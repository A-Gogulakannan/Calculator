from flask import Flask, request, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import math
import re
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///calculator.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Database Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    calculations = db.relationship('Calculation', backref='user', lazy=True)

class Calculation(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    expression = db.Column(db.String(500), nullable=False)
    result = db.Column(db.String(100), nullable=False)
    calculation_type = db.Column(db.String(20), default='basic')
    custom_name = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Create tables
with app.app_context():
    db.create_all()

# Serve the main calculator page
@app.route('/')
def index():
    return send_from_directory('static', 'calculator.html')

# Calculator API endpoint
@app.route('/api/calculate', methods=['POST'])
def calculate():
    try:
        data = request.get_json()
        expression = data.get('expression', '')
        calculation_type = data.get('calculation_type', 'basic')
        
        if not expression:
            return jsonify({"success": False, "message": "No expression provided"}), 400
        
        # Clean and prepare the expression
        expression = expression.strip()
        
        # Replace mathematical constants
        expression = expression.replace('pi', str(math.pi))
        expression = expression.replace('e', str(math.e))
        
        # Handle scientific functions
        if calculation_type == 'scientific':
            # Replace scientific functions with math module equivalents
            expression = re.sub(r'sin\(([^)]+)\)', r'math.sin(math.radians(\1))', expression)
            expression = re.sub(r'cos\(([^)]+)\)', r'math.cos(math.radians(\1))', expression)
            expression = re.sub(r'tan\(([^)]+)\)', r'math.tan(math.radians(\1))', expression)
            expression = re.sub(r'log\(([^)]+)\)', r'math.log10(\1)', expression)
            expression = re.sub(r'ln\(([^)]+)\)', r'math.log(\1)', expression)
            expression = re.sub(r'sqrt\(([^)]+)\)', r'math.sqrt(\1)', expression)
        
        # Handle power operator
        expression = expression.replace('^', '**')
        
        # Evaluate the expression safely
        # Only allow safe mathematical operations
        allowed_names = {
            "__builtins__": {},
            "math": math,
            "abs": abs,
            "round": round,
            "min": min,
            "max": max,
        }
        
        result = eval(expression, allowed_names)
        
        # Format the result
        if isinstance(result, float):
            if result.is_integer():
                result = int(result)
            else:
                result = round(result, 10)
        
        return jsonify({
            "success": True,
            "result": result,
            "expression": data.get('expression', ''),
            "calculation_type": calculation_type
        })
        
    except ZeroDivisionError:
        return jsonify({"success": False, "message": "Division by zero"}), 400
    except ValueError as e:
        return jsonify({"success": False, "message": f"Math error: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"success": False, "message": f"Invalid expression: {str(e)}"}), 400

# Authentication endpoints
@app.route('/api/auth/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username = data.get('username', '').strip()
        
        if not username:
            return jsonify({"success": False, "message": "Username is required"}), 400
        
        if len(username) > 80:
            return jsonify({"success": False, "message": "Username too long"}), 400
        
        # Find or create user
        user = User.query.filter_by(username=username).first()
        if not user:
            user = User(username=username)
            db.session.add(user)
            db.session.commit()
        
        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "id": user.id,
                "username": user.username,
                "created_at": user.created_at.isoformat()
            }
        })
        
    except Exception as e:
        return jsonify({"success": False, "message": f"Login error: {str(e)}"}), 500

# Save calculation endpoint
@app.route('/api/calculations', methods=['POST'])
def save_calculation():
    try:
        data = request.get_json()
        username = data.get('username')
        expression = data.get('expression')
        result = data.get('result')
        calculation_type = data.get('calculation_type', 'basic')
        custom_name = data.get('custom_name')
        
        if not all([username, expression, result]):
            return jsonify({"success": False, "message": "Missing required fields"}), 400
        
        # Find user
        user = User.query.filter_by(username=username).first()
        if not user:
            return jsonify({"success": False, "message": "User not found"}), 404
        
        # Create calculation
        calculation = Calculation(
            user_id=user.id,
            expression=expression,
            result=str(result),
            calculation_type=calculation_type,
            custom_name=custom_name
        )
        
        db.session.add(calculation)
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": "Calculation saved successfully",
            "calculation": {
                "id": calculation.id,
                "expression": calculation.expression,
                "result": calculation.result,
                "custom_name": calculation.custom_name,
                "created_at": calculation.created_at.isoformat()
            }
        })
        
    except Exception as e:
        return jsonify({"success": False, "message": f"Save error: {str(e)}"}), 500

# Get user's calculation history
@app.route('/api/calculations/<username>', methods=['GET'])
def get_calculations(username):
    try:
        user = User.query.filter_by(username=username).first()
        if not user:
            return jsonify({"success": False, "message": "User not found"}), 404
        
        calculations = Calculation.query.filter_by(user_id=user.id).order_by(Calculation.created_at.desc()).all()
        
        calc_list = []
        for calc in calculations:
            calc_list.append({
                "id": calc.id,
                "expression": calc.expression,
                "result": calc.result,
                "calculation_type": calc.calculation_type,
                "custom_name": calc.custom_name,
                "created_at": calc.created_at.isoformat()
            })
        
        return jsonify({
            "success": True,
            "calculations": calc_list,
            "total": len(calc_list)
        })
        
    except Exception as e:
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500

# Delete calculation
@app.route('/api/calculations/<username>/<int:calc_id>', methods=['DELETE'])
def delete_calculation(username, calc_id):
    try:
        user = User.query.filter_by(username=username).first()
        if not user:
            return jsonify({"success": False, "message": "User not found"}), 404
        
        calculation = Calculation.query.filter_by(id=calc_id, user_id=user.id).first()
        if not calculation:
            return jsonify({"success": False, "message": "Calculation not found"}), 404
        
        db.session.delete(calculation)
        db.session.commit()
        
        return jsonify({"success": True, "message": "Calculation deleted successfully"})
        
    except Exception as e:
        return jsonify({"success": False, "message": f"Delete error: {str(e)}"}), 500

# Clear all calculations for user
@app.route('/api/calculations/<username>/clear-all', methods=['DELETE'])
def clear_all_calculations(username):
    try:
        user = User.query.filter_by(username=username).first()
        if not user:
            return jsonify({"success": False, "message": "User not found"}), 404
        
        count = Calculation.query.filter_by(user_id=user.id).count()
        if count == 0:
            return jsonify({"success": False, "message": "No calculations to delete"}), 400
        
        Calculation.query.filter_by(user_id=user.id).delete()
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": f"Successfully deleted {count} calculations",
            "deleted_count": count
        })
        
    except Exception as e:
        return jsonify({"success": False, "message": f"Clear error: {str(e)}"}), 500

# Health check endpoint
@app.route('/health')
def health_check():
    return jsonify({"status": "healthy", "message": "Calculator API is running"})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)