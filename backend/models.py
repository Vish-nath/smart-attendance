from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class TimetableEntry(db.Model):
    __tablename__ = 'timetable_entries'

    id = db.Column(db.Integer, primary_key=True)
    day_index = db.Column(db.Integer, nullable=False)  # 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    slot_index = db.Column(db.Integer, nullable=False) # 0 to 6
    subject = db.Column(db.String(80), nullable=False, default="")

    __table_args__ = (
        db.UniqueConstraint('day_index', 'slot_index', name='_day_slot_uc'),
    )

    to_dict = lambda self: {
        'id': self.id,
        'day_index': self.day_index,
        'slot_index': self.slot_index,
        'subject': self.subject
    }

class AttendanceRecord(db.Model):
    __tablename__ = 'attendance_records'

    id = db.Column(db.String(100), primary_key=True) # e.g., "class:2025-03-30:0"
    date = db.Column(db.String(10), nullable=False)   # "YYYY-MM-DD"
    slot = db.Column(db.Integer, nullable=False)      # 0 to 6
    subject = db.Column(db.String(80), nullable=False)
    status = db.Column(db.String(20), nullable=False) # "present", "absent", "cancelled"
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date,
            'slot': self.slot,
            'subject': self.subject,
            'status': self.status,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

class ExtraClass(db.Model):
    __tablename__ = 'extra_classes'

    id = db.Column(db.String(100), primary_key=True)  # unique ID
    date = db.Column(db.String(10), nullable=False)    # "YYYY-MM-DD"
    slot = db.Column(db.Integer, nullable=False)       # 0 to 6
    subject = db.Column(db.String(80), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date,
            'slot': self.slot,
            'subject': self.subject
        }
