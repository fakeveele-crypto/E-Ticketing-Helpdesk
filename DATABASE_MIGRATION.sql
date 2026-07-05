-- Database Migration Guide for Ticket Workflow System

-- 1. Add new columns to tickets table
ALTER TABLE tickets ADD COLUMN received_by_admin_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE tickets ADD COLUMN forwarded_to_helpdesk_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE tickets ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;

-- 2. Create ticket_tracking table for audit trail
CREATE TABLE IF NOT EXISTS ticket_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  actor_id UUID,
  actor_name TEXT,
  actor_role TEXT,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_action CHECK (action IN ('created', 'accepted_by_admin', 'forwarded_to_helpdesk', 'accepted_by_helpdesk', 'completed'))
);

-- 3. Create indexes for performance
CREATE INDEX idx_ticket_tracking_ticket_id ON ticket_tracking(ticket_id);
CREATE INDEX idx_ticket_tracking_created_at ON ticket_tracking(created_at);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);

-- 4. Update existing tickets status values if needed
-- This changes old 'open' status to 'new' for new tickets
-- But keeps 'on_progress' and 'closed' as they are
-- UPDATE tickets SET status = 'new' WHERE status = 'open' AND created_at > NOW() - INTERVAL '7 days';

-- 5. Enable RLS (Row Level Security) on ticket_tracking if needed
ALTER TABLE ticket_tracking ENABLE ROW LEVEL SECURITY;

-- 6. Add policies for ticket_tracking table
CREATE POLICY ticket_tracking_select ON ticket_tracking
  FOR SELECT
  USING (true);

CREATE POLICY ticket_tracking_insert ON ticket_tracking
  FOR INSERT
  WITH CHECK (true);

-- 7. Support role-based notifications in notifications table
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS recipient_role TEXT;

ALTER TABLE notifications
  ALTER COLUMN recipient_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_role ON notifications(recipient_role);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications(recipient_id);

-- Note: Adjust RLS policies based on your security requirements
