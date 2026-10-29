import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from models import db, TimetableEntry, AttendanceRecord, ExtraClass

app = Flask(__name__)

# Configure SQLite Database
db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'classmate.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

CORS(app, resources={r"/api/*": {"origins": "*"}})
db.init_app(app)

with app.app_context():
    db.create_all()

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok', 'service': 'Classmate Flask Backend'}), 200

@app.route('/api/sync', methods=['GET'])
def get_full_data():
    """Returns all timetable, attendance, and extra class data in Classmate JSON format."""
    # Fetch timetable (7 days x 7 slots)
    timetable = [["" for _ in range(7)] for _ in range(7)]
    entries = TimetableEntry.query.all()
    for e in entries:
        if 0 <= e.day_index < 7 and 0 <= e.slot_index < 7:
            timetable[e.day_index][e.slot_index] = e.subject

    # Fetch attendance
    attendance = {}
    records = AttendanceRecord.query.all()
    for r in records:
        attendance[r.id] = r.to_dict()

    # Fetch extras
    extras = {}
    extra_records = ExtraClass.query.all()
    for ex in extra_records:
        if ex.date not in extras:
            extras[ex.date] = []
        extras[ex.date].append(ex.to_dict())

    return jsonify({
        'version': 1,
        'timetable': timetable,
        'attendance': attendance,
        'extras': extras,
        'notified': {}
    }), 200

@app.route('/api/sync', methods=['POST'])
def save_full_data():
    """Bulk updates or imports full data set."""
    payload = request.get_json(silent=True)
    if not payload or not isinstance(payload, dict):
        return jsonify({'error': 'Invalid JSON payload'}), 400

    try:
        # Update Timetable if provided
        if 'timetable' in payload and isinstance(payload['timetable'], list):
            TimetableEntry.query.delete()
            for day_idx, day_slots in enumerate(payload['timetable']):
                if isinstance(day_slots, list):
                    for slot_idx, subject in enumerate(day_slots):
                        if subject and isinstance(subject, str):
                            entry = TimetableEntry(day_index=day_idx, slot_index=slot_idx, subject=subject.strip())
                            db.session.add(entry)

        # Update Attendance if provided
        if 'attendance' in payload and isinstance(payload['attendance'], dict):
            for record_id, rec in payload['attendance'].items():
                if isinstance(rec, dict) and 'date' in rec and 'subject' in rec and 'status' in rec and 'slot' in rec:
                    existing = AttendanceRecord.query.get(record_id)
                    if existing:
                        existing.subject = rec['subject']
                        existing.status = rec['status']
                        existing.slot = rec['slot']
                    else:
                        new_rec = AttendanceRecord(
                            id=record_id,
                            date=rec['date'],
                            slot=rec['slot'],
                            subject=rec['subject'],
                            status=rec['status']
                        )
                        db.session.add(new_rec)

        # Update Extras if provided
        if 'extras' in payload and isinstance(payload['extras'], dict):
            for date_str, items in payload['extras'].items():
                if isinstance(items, list):
                    for item in items:
                        if isinstance(item, dict) and 'id' in item and 'subject' in item and 'slot' in item:
                            existing_ex = ExtraClass.query.get(item['id'])
                            if not existing_ex:
                                new_ex = ExtraClass(
                                    id=item['id'],
                                    date=date_str,
                                    slot=item['slot'],
                                    subject=item['subject']
                                )
                                db.session.add(new_ex)

        db.session.commit()
        return jsonify({'message': 'Data synchronized successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to sync data: {str(e)}'}), 500

@app.route('/api/timetable', methods=['GET', 'POST'])
def handle_timetable():
    if request.method == 'GET':
        timetable = [["" for _ in range(7)] for _ in range(7)]
        entries = TimetableEntry.query.all()
        for e in entries:
            if 0 <= e.day_index < 7 and 0 <= e.slot_index < 7:
                timetable[e.day_index][e.slot_index] = e.subject
        return jsonify({'timetable': timetable}), 200

    elif request.method == 'POST':
        data = request.get_json(silent=True)
        if not data or 'timetable' not in data:
            return jsonify({'error': 'Missing timetable matrix'}), 400

        try:
            TimetableEntry.query.delete()
            for day_idx, day_slots in enumerate(data['timetable']):
                for slot_idx, subject in enumerate(day_slots):
                    if subject and isinstance(subject, str) and subject.strip():
                        db.session.add(TimetableEntry(
                            day_index=day_idx,
                            slot_index=slot_idx,
                            subject=subject.strip()
                        ))
            db.session.commit()
            return jsonify({'message': 'Timetable updated successfully'}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e)}), 500

@app.route('/api/attendance', methods=['GET', 'POST', 'DELETE'])
def handle_attendance():
    if request.method == 'GET':
        records = AttendanceRecord.query.all()
        return jsonify({'attendance': {r.id: r.to_dict() for r in records}}), 200

    elif request.method == 'POST':
        data = request.get_json(silent=True)
        if not data or not all(k in data for k in ('id', 'date', 'slot', 'subject', 'status')):
            return jsonify({'error': 'Missing required fields'}), 400

        try:
            record = AttendanceRecord.query.get(data['id'])
            if record:
                record.status = data['status']
                record.subject = data['subject']
                record.slot = data['slot']
            else:
                record = AttendanceRecord(
                    id=data['id'],
                    date=data['date'],
                    slot=data['slot'],
                    subject=data['subject'],
                    status=data['status']
                )
                db.session.add(record)
            db.session.commit()
            return jsonify({'message': 'Attendance recorded', 'record': record.to_dict()}), 200
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': str(e)}), 500

    elif request.method == 'DELETE':
        record_id = request.args.get('id')
        if not record_id:
            return jsonify({'error': 'Record ID is required'}), 400

        record = AttendanceRecord.query.get(record_id)
        if record:
            db.session.delete(record)
            db.session.commit()
            return jsonify({'message': 'Record deleted'}), 200
        return jsonify({'error': 'Record not found'}), 404

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
