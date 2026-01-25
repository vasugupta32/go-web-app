# Go Web Application - Personal Portfolio

A clean and professional portfolio website built with Golang. This project demonstrates proficiency in Go backend development using only the standard library.

## Features

✅ Lightweight web server using Go's `net/http` package  
✅ Clean and maintainable code structure  
✅ Responsive HTML pages with modern CSS styling  
✅ Health check endpoint for monitoring  
✅ Unit tests included  
✅ Production-ready logging  

## Quick Start

**Run the application:**
```bash
go run main.go
```

**Build and run:**
```bash
go build -o go-web-app .
./go-web-app
```

**Run tests:**
```bash
go test -v ./...
```

## Access the Application

Once running, visit:
- 🏠 **Home**: http://localhost:8080/home
- 👤 **About**: http://localhost:8080/about
- 💼 **Projects**: http://localhost:8080/courses
- 📧 **Contact**: http://localhost:8080/contact
- 🏥 **Health**: http://localhost:8080/health

## Tech Stack

- **Language**: Go 1.22.5
- **Framework**: net/http (standard library)
- **Frontend**: HTML5, CSS3

## Project Structure

```
go-web-app/
├── main.go           # Server with route handlers
├── main_test.go      # Unit tests
├── go.mod            # Go module definition
├── static/           # Static HTML and CSS
│   ├── home.html
│   ├── about.html
│   ├── courses.html
│   ├── contact.html
│   └── images/
└── README.md
```

## Why This Project?

This project demonstrates:
- Clean Go code following best practices
- RESTful routing with standard library
- Serving static files efficiently
- Production-ready features (logging, health checks)
- Test-driven development

Perfect for showcasing in a DevOps/Backend Developer portfolio!

## Author

**Vasu Gupta**
- GitHub: [@vasugupta32](https://github.com/vasugupta32)
- LinkedIn: [vasugupta32](https://www.linkedin.com/in/vasugupta32/)

## License

Apache License 2.0 - see LICENSE file for details.


