# Task Manager App 📋

## 🌟 Overview
A modern, feature-rich task management application built with **Flutter** and **Firebase**, designed to boost productivity and organize daily schedules efficiently.

# 💻 Tech Stack:
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

## ✨ Key Features

### 🎯 **Smart Task Management**
- **Create detailed tasks** with titles, descriptions, date, and time
- **Intelligent status tracking** - Upcoming, Due Soon (30min), Overdue, Completed
- **Automatic color coding** based on task urgency
- **Real-time synchronization** across all devices

### ⚡ **Smart Scheduling**
- **Time-gap validation** - Ensures minimum 3-minute intervals between tasks
- **Duplicate prevention** - Blocks same-day task duplicates
- **Priority-based organization** - Visual categorization of tasks

### 🔍 **Advanced Filtering & Search**
- **Multiple filter views**: Today, All, Completed, Pending, Custom Date
- **Instant search** by title or description
- **Smart categorization** in Today view (Overdue/Upcoming/Completed)
- **Date-based filtering** with calendar selection

### 📊 **Productivity Analytics**
- **Visual statistics dashboard** with completion metrics
- **Progress tracking** with percentage indicators
- **Daily completion rates**
- **Task distribution insights**

### 🔐 **Secure & Reliable**
- **Firebase Authentication** for secure login
- **Cloud synchronization** with Firebase Realtime Database
- **Data persistence** and offline capability
- **User-specific task isolation**

## 🎨 User Interface
- **Material Design** with Cupertino elements
- **Color-coded task cards** based on status
- **Responsive layout** for all screen sizes
- **Gesture-based interactions** (tap, long-press)
- **Quick task completion** with single tap
- **Edit/Delete** via context menus

## 🛠 Technical Implementation
- **Flutter Framework** - Cross-platform development
- **Firebase Auth** - User authentication
- **Firebase Realtime DB** - Cloud data storage
- **Material Design** - UI components
- **Provider Pattern** - State management

## 📱 Screens
- **Home Screen** - Dashboard with statistics and task list
- **Add/Edit Task** - Form with validation and scheduling
- **Search Screen** - Full-text search across all tasks
- **Filter Options** - Custom task views

## 🚀 Getting Started

```bash
# Clone repository
git clone https://github.com/To-Do-Note-Flutter/task-manager.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🔧 Setup & Installation
### **Prerequisites**
- Flutter SDK (latest version)
- Firebase project setup
- Android Studio / VS Code

### **Configuration**
1. Clone the repository
2. Add Firebase configuration files
3. Run `flutter pub get`
4. Configure Firebase Authentication
5. Set up Realtime Database rules

## 📊 Database Structure
```json
"tasks": {
  "userId": {
    "taskId": {
      "title": "String",
      "description": "String",
      "date": "timestamp",
      "time": {"hour": int, "minute": int},
      "isCompleted": "boolean",
      "createdAt": "timestamp",
      "completedAt": "timestamp"
    }
  }
}
```

## 🎯 Use Cases
- **For Students**: Assignment tracking, class schedule organization
- **For Professionals**: Meeting scheduling, project task management
- **Personal Use**: Daily to-do lists, appointment reminders, habit tracking

## 🚀 Future Enhancements
- Push notifications for upcoming tasks
- Task categories and tags
- Recurring tasks
- File attachments
- Calendar integration
- Export to PDF/Excel
- AI-powered task suggestions

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer
Built with ❤️ using **Flutter** & **Firebase**

---
## 📊 GitHub Stats:
![](https://github-readme-stats.vercel.app/api?username=To-Do-Note-Flutter&theme=onedark&hide_border=false&include_all_commits=true&count_private=true)<br/>
![](https://nirzak-streak-stats.vercel.app/?user=To-Do-Note-Flutter&theme=onedark&hide_border=false)<br/>
![](https://github-readme-stats.vercel.app/api/top-langs/?username=To-Do-Note-Flutter&theme=onedark&hide_border=false&include_all_commits=true&count_private=true&layout=compact)

## 🏆 GitHub Trophies
![](https://github-profile-trophy.vercel.app/?username=To-Do-Note-Flutter&theme=radical&no-frame=false&no-bg=true&margin-w=4)

### ✍️ Random Dev Quote
![](https://quotes-github-readme.vercel.app/api?type=horizontal&theme=radical)

### 🔝 Top Contributed Repo
![](https://github-contributor-stats.vercel.app/api?username=To-Do-Note-Flutter&limit=5&theme=dark&combine_all_yearly_contributions=true)

---
[![](https://visitcount.itsvg.in/api?id=To-Do-Note-Flutter&icon=0&color=0)](https://visitcount.itsvg.in)

**⭐ Star this repository if you find it helpful!**

*Elevate your productivity with intelligent task management!* 🚀

*Stay organized, stay productive, achieve more!*

<!-- Proudly created with GPRM (https://gprm.itsvg.in) -->
