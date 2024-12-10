# Cigarette Detection Flutter App

This Flutter-based app uses **Google ML Kit** and **TensorFlow** to detect people who are smoking in real-time. The app leverages **face detection** and **image detection** technologies to identify smoking individuals.

## Features
- **Face Detection**: Detects user faces and analyzes whether they are smoking.
- **Image Detection**: A model trained with TensorFlow identifies smoking people using images sourced from Kaggle.
- **Real-time Performance**: Utilizes Google ML Kit for fast and accurate real-time image analysis.

## Technologies Used
- **Flutter**: Mobile application development.
- **Google ML Kit**: For face and image detection.
- **TensorFlow**: For training and integrating the deep learning model.
- **Kaggle**: Platform providing the training dataset.

## App Flow
1. The user opens the app and grants camera permission.
2. The app performs real-time face detection.
3. After detecting the face, it analyzes the smoking status and displays the result.

## Installation

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/username/smoking-detection.git
