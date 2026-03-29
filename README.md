# 🚀 Go Web Application – Personal Portfolio

[![Go Version](https://img.shields.io/badge/Go-1.22.5-blue?logo=go)](https://golang.org)
[![Read on Medium](https://img.shields.io/badge/Read%20Detailed%20Blog-Medium-black?logo=medium)](https://medium.com/@vasugupt32/building-a-complete-ci-cd-pipeline-for-a-go-web-app-from-code-to-kubernetes-in-3-minutes-033340704f4d)

A clean, lightweight, and production-ready portfolio web application built using **Golang’s standard library (`net/http`)**.
This project demonstrates strong backend fundamentals along with real-world **DevOps practices (CI/CD, containerization, deployment)**.

---

## 📖 Detailed Blog

I’ve written a complete step-by-step guide covering CI/CD pipeline, Docker, and Kubernetes deployment:

👉 https://medium.com/@vasugupt32/building-a-complete-ci-cd-pipeline-for-a-go-web-app-from-code-to-kubernetes-in-3-minutes-033340704f4d

---

## ✨ Features

* ✅ Lightweight HTTP server using Go standard library
* ✅ Clean and maintainable project structure
* ✅ Responsive UI with modern HTML & CSS
* ✅ Health check endpoint for monitoring
* ✅ Structured logging for production readiness
* ✅ Unit testing support
* ✅ Static file serving

---

## 🛠️ Tech Stack

* **Language**: Go 1.22.5
* **Backend**: net/http (Standard Library)
* **Frontend**: HTML5, CSS3
* **CI/CD**: GitHub Actions / Jenkins (as per blog)
* **Containerization**: Docker
* **Orchestration**: Kubernetes

---

## 🚀 Getting Started

### ▶️ Run the application

```bash
go run main.go
```

### ⚙️ Build and run

```bash
go build -o go-web-app
./go-web-app
```

### 🧪 Run tests

```bash
go test -v ./...
```

---

## 🌐 Application Endpoints

| Endpoint   | Description       |
| ---------- | ----------------- |
| `/home`    | Home page         |
| `/about`   | About page        |
| `/courses` | Projects showcase |
| `/contact` | Contact page      |
| `/health`  | Health check      |

Access locally:
👉 http://localhost:8080

---

## 📁 Project Structure

```
go-web-app/
├── main.go           # Application entry point & route handlers
├── main_test.go      # Unit tests
├── go.mod            # Go module definition
├── static/           # Static assets
│   ├── home.html
│   ├── about.html
│   ├── courses.html
│   ├── contact.html
│   └── images/
└── README.md
```

---

## 🎯 Key Highlights

* Built using pure Go (no external frameworks)
* Demonstrates backend + DevOps integration
* CI/CD pipeline from code → Docker → Kubernetes
* Production-ready structure with monitoring capability

---

## 📈 Future Improvements

* Add Prometheus & Grafana monitoring
* Deploy using Nomad (HashiCorp stack)
* Add authentication (JWT-based)
* Improve UI/UX design

---

## 👨‍💻 Author

**Vasu Gupta**

* GitHub: https://github.com/vasugupta32
* LinkedIn: https://www.linkedin.com/in/vasugupta32/

---

## 📄 License

This project is open-source and available under the MIT License.
