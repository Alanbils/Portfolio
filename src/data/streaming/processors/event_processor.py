#!/usr/bin/env python3
"""
Kinesis Event Stream Processor

This application processes real-time event data from a Kinesis stream,
transforms it, and outputs the processed data to another Kinesis stream.
"""

import json
import base64
import boto3
import time
import logging
import os
import datetime
from typing import Dict, List, Any, Optional
from amazon_kclpy import kcl
from amazon_kclpy.v3 import processor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize AWS clients
kinesis_client = boto3.client('kinesis', region_name=os.environ.get('AWS_REGION', 'us-west-2'))

# Get configuration from environment variables
OUTPUT_STREAM = os.environ.get('OUTPUT_STREAM', 'processed-events')
ERROR_STREAM = os.environ.get('ERROR_STREAM', 'error-events')
EVENT_TIME_FIELD = os.environ.get('EVENT_TIME_FIELD', 'timestamp')
BATCH_SIZE = int(os.environ.get('BATCH_SIZE', '100'))


class EventProcessor(processor.RecordProcessorBase):
    """
    Processes records from a Kinesis stream and forwards processed results.
    """
    
    def __init__(self):
        self.shutdown_requested = False
        self.checkpoint_error_sleep_seconds = 5
        self.batch_records = []
        self.batch_size = BATCH_SIZE
        self.last_checkpoint_time = time.time()
        self.checkpoint_interval_seconds = 60  # Checkpoint every minute
    
    def initialize(self, initialize_input):
        """
        Initialize the record processor.
        
        Args:
            initialize_input: Information about the shard assignment
        """
        self.shard_id = initialize_input.shard_id
        logger.info(f"Initialized processor for shard {self.shard_id}")
    
    def process_records(self, process_records_input):
        """
        Process a batch of records from the Kinesis stream.
        
        Args:
            process_records_input: The records to be processed
        """
        records = process_records_input.records
        logger.info(f"Processing {len(records)} records from shard {self.shard_id}")
        
        for record in records:
            try:
                data = self._parse_record_data(record)
                if data:
                    processed_data = self._process_event(data)
                    self.batch_records.append(processed_data)
                    
                    # If we've collected enough records, send them as a batch
                    if len(self.batch_records) >= self.batch_size:
                        self._send_records_to_kinesis()
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                self._send_to_error_stream(record.data, str(e))
        
        # Checkpoint if it's been long enough or shutdown is requested
        if (time.time() - self.last_checkpoint_time > self.checkpoint_interval_seconds
                or process_records_input.checkpointer.checkpoint_input.shutdown_requested):
            self._checkpoint(process_records_input.checkpointer)
    
    def lease_lost(self, lease_lost_input):
        """
        Called when the processor loses its lease and can no longer accept new records.
        
        Args:
            lease_lost_input: Information about the lease loss
        """
        logger.info(f"Lease lost for shard {self.shard_id}")
        # Send any remaining records
        if self.batch_records:
            self._send_records_to_kinesis()
    
    def shard_ended(self, shard_ended_input):
        """
        Called when the shard is closed for processing.
        
        Args:
            shard_ended_input: Information about the shard end
        """
        logger.info(f"Shard {self.shard_id} ended")
        # Send any remaining records
        if self.batch_records:
            self._send_records_to_kinesis()
        
        # Checkpoint to signal that processing of this shard is complete
        self._checkpoint(shard_ended_input.checkpointer)
    
    def shutdown_requested(self, shutdown_requested_input):
        """
        Called when the KCL is being shutdown.
        
        Args:
            shutdown_requested_input: Information about the shutdown request
        """
        logger.info(f"Shutdown requested for shard {self.shard_id}")
        self.shutdown_requested = True
        
        # Send any remaining records
        if self.batch_records:
            self._send_records_to_kinesis()
        
        # Checkpoint to signal that we've processed all records
        self._checkpoint(shutdown_requested_input.checkpointer)
    
    def _parse_record_data(self, record):
        """
        Parse the data from a Kinesis record.
        
        Args:
            record: The Kinesis record
            
        Returns:
            Parsed JSON data or None if parsing fails
        """
        try:
            data = base64.b64decode(record.data).decode('utf-8')
            return json.loads(data)
        except Exception as e:
            logger.error(f"Error parsing record data: {str(e)}")
            self._send_to_error_stream(record.data, f"Parsing error: {str(e)}")
            return None
    
    def _process_event(self, event_data):
        """
        Process a single event.
        
        Args:
            event_data: The event data to process
            
        Returns:
            Processed event data
        """
        # Add processing timestamp
        event_data['processing_timestamp'] = datetime.datetime.utcnow().isoformat()
        
        # Normalize event type to uppercase
        if 'event_type' in event_data:
            event_data['event_type'] = event_data['event_type'].upper()
        
        # Add event category based on event_type
        if 'event_type' in event_data:
            event_type = event_data['event_type']
            if 'CLICK' in event_type or 'VIEW' in event_type:
                event_data['event_category'] = 'USER_INTERACTION'
            elif 'PURCHASE' in event_type or 'PAYMENT' in event_type:
                event_data['event_category'] = 'TRANSACTION'
            elif 'ERROR' in event_type or 'EXCEPTION' in event_type:
                event_data['event_category'] = 'SYSTEM_ERROR'
            else:
                event_data['event_category'] = 'OTHER'
        
        # Calculate event lag if event_time is present
        if EVENT_TIME_FIELD in event_data and event_data[EVENT_TIME_FIELD]:
            try:
                event_time = datetime.datetime.fromisoformat(event_data[EVENT_TIME_FIELD].replace('Z', '+00:00'))
                now = datetime.datetime.utcnow()
                lag_seconds = (now - event_time).total_seconds()
                event_data['event_lag_seconds'] = lag_seconds
            except Exception as e:
                logger.warning(f"Could not calculate event lag: {str(e)}")
        
        return event_data
    
    def _send_records_to_kinesis(self):
        """Send the batch of records to the output Kinesis stream."""
        if not self.batch_records:
            return
        
        logger.info(f"Sending {len(self.batch_records)} records to Kinesis")
        
        try:
            # Convert records to Kinesis format
            kinesis_records = [
                {
                    'Data': json.dumps(record).encode('utf-8'),
                    'PartitionKey': str(record.get('id', hash(json.dumps(record))))
                }
                for record in self.batch_records
            ]
            
            # Send records to Kinesis in batches of 500 (Kinesis limit)
            for i in range(0, len(kinesis_records), 500):
                batch = kinesis_records[i:i+500]
                response = kinesis_client.put_records(
                    Records=batch,
                    StreamName=OUTPUT_STREAM
                )
                
                # Check for failures
                failed_count = response.get('FailedRecordCount', 0)
                if failed_count > 0:
                    logger.warning(f"{failed_count} records failed to send to Kinesis")
            
            # Clear the batch
            self.batch_records = []
            
        except Exception as e:
            logger.error(f"Error sending records to Kinesis: {str(e)}")
    
    def _send_to_error_stream(self, record_data, error_message):
        """
        Send a record to the error stream.
        
        Args:
            record_data: The original record data
            error_message: The error message
        """
        try:
            error_record = {
                'original_data': base64.b64encode(record_data).decode('utf-8'),
                'error_message': error_message,
                'shard_id': self.shard_id,
                'timestamp': datetime.datetime.utcnow().isoformat()
            }
            
            kinesis_client.put_record(
                StreamName=ERROR_STREAM,
                Data=json.dumps(error_record).encode('utf-8'),
                PartitionKey=str(hash(json.dumps(error_record)))
            )
        except Exception as e:
            logger.error(f"Error sending to error stream: {str(e)}")
    
    def _checkpoint(self, checkpointer):
        """
        Checkpoint progress processing the shard.
        
        Args:
            checkpointer: The checkpointer object
        """
        try:
            checkpointer.checkpoint()
            self.last_checkpoint_time = time.time()
            logger.info(f"Checkpoint successful for shard {self.shard_id}")
        except Exception as e:
            logger.error(f"Checkpoint error: {str(e)}")
            time.sleep(self.checkpoint_error_sleep_seconds)


if __name__ == "__main__":
    # Start the KCL worker process
    kcl_process = kcl.KCLProcess(processor.V3Processor(EventProcessor()))
    kcl_process.run()