Here is a comprehensive English description for your GitHub repository:

---

# Task Manager App (Flutter)

A modern, fully-featured task management app built with Flutter. This application helps users organize, track, and manage their daily tasks efficiently, with a focus on flexibility, customization, and a beautiful user experience.

## Features

- **Dynamic Categories:**  
  Users can create, edit, and delete task categories. Categories are stored locally using Hive, allowing for full customization beyond static enums.

- **Advanced Filtering:**  
  Filter tasks by category, priority, status (completed/pending), and due date. Multiple filters can be combined for precise task management.

- **Instant Search:**  
  Real-time search bar in the main screen to quickly find tasks by title, description, category, or priority.

- **Smart Notifications:**  
  - Persistent notifications for active tasks.
  - Scheduled reminders before due dates.
  - Optional weekly recurring notifications (choose days of the week and time).
  - All notifications are managed locally and are automatically cancelled when a task is completed or deleted.

- **Statistics Dashboard:**  
  Visual statistics for your tasks, including completion rates, overdue tasks, and distribution by category and priority.

- **Theme Support:**  
  Instantly switch between light and dark themes. All screens react to theme changes in real time.

- **Modern UI:**  
  Clean, responsive, and user-friendly interface with support for Arabic (RTL) and beautiful material design components.

## Technologies Used

- **Flutter** (cross-platform mobile framework)
- **Hive** (local NoSQL database for fast, offline storage)
- **Provider** (state management)
- **flutter_local_notifications** (local notifications and scheduling)
- **Dart** (main programming language)

## Screenshots

(Add your screenshots here)

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

- model – Data models (Task, TaskType, Priority, etc.)
- services – Local storage and category management (Hive)
- view – All UI screens (home, add/edit task, category management, stats, etc.)
- helpers – Notification service and utility functions

## Why use this app?

- **Customizable:** You are not limited to predefined categories—create your own!
- **Productive:** Advanced filters and search help you focus on what matters.
- **Reliable:** All data is stored locally and works offline.
- **Beautiful:** Modern design with smooth animations and theme support.

## License

This project is open source and available under the MIT License.

---

Feel free to copy, modify, and add your own screenshots or usage instructions!
