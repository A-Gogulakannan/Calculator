# Calculator App

A modern, responsive calculator web application with both basic and scientific modes.

## Features

✅ **Basic Calculator**
- Addition, subtraction, multiplication, division
- Decimal point support
- Clear functions (C, CE, Backspace)

✅ **Scientific Calculator**
- Trigonometric functions (sin, cos, tan)
- Logarithmic functions (log, ln)
- Square root and power operations
- Mathematical constants (π, e)

✅ **User Interface**
- Clean, modern design
- Dark/Light theme toggle
- Responsive layout for mobile devices
- Keyboard support for all operations

✅ **Additional Features**
- Real-time expression display
- Error handling with user-friendly messages
- History display showing current calculation

## Installation

1. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the application:**
   ```bash
   python app.py
   ```

3. **Open your browser and go to:**
   ```
   http://localhost:5000
   ```

## Usage

### Basic Mode
- Click numbers and operators to build expressions
- Press `=` or Enter to calculate
- Use `C` to clear all, `CE` to clear entry, `⌫` to delete last character

### Scientific Mode
- Switch to Scientific mode using the toggle
- Access trigonometric functions: sin, cos, tan
- Use logarithmic functions: log (base 10), ln (natural log)
- Add mathematical constants: π (pi), e (Euler's number)
- Use power operator: x^y

### Keyboard Shortcuts
- **Numbers (0-9):** Input numbers
- **Operators (+, -, *, /):** Mathematical operations
- **Enter or =:** Calculate result
- **Escape:** Clear all
- **Backspace:** Delete last character
- **Decimal point (.):** Add decimal point

### Theme Toggle
- Click the 🌙/☀️ button in the top-right corner to switch between light and dark themes

## API Endpoints

### POST /api/calculate
Calculate mathematical expressions.

**Request:**
```json
{
  "expression": "2 + 3 * 4",
  "calculation_type": "basic"
}
```

**Response:**
```json
{
  "success": true,
  "result": 14,
  "expression": "2 + 3 * 4",
  "calculation_type": "basic"
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "message": "Calculator API is running"
}
```

## Project Structure

```
calculator-app/
├── app.py                 # Flask backend server
├── requirements.txt       # Python dependencies
├── README.md             # Project documentation
└── static/
    └── calculator.html   # Frontend calculator interface
```

## Technologies Used

- **Backend:** Flask (Python)
- **Frontend:** HTML5, CSS3, JavaScript
- **Styling:** Modern CSS with gradients and animations
- **Math Operations:** Python's math module for scientific functions

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Mobile browsers (iOS Safari, Chrome Mobile)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the MIT License.