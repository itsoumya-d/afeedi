# Afeedi - Personalized Content Aggregator

## Overview
Afeedi is a modern content aggregation platform that delivers personalized content recommendations based on user preferences, viewing habits, and contextual factors. The application features an enhanced onboarding process that collects comprehensive user preferences to power a sophisticated recommendation engine.

## Key Features

### Enhanced Onboarding Experience
- **Multi-step Onboarding Flow**: Intuitive, animated onboarding process with progress tracking
- **Comprehensive Preference Collection**: Captures detailed user preferences including:
  - Personal information and demographics
  - Content interests with visual selection grid
  - Platform preferences with priority sliders
  - Content type preferences
  - Viewing habits (time of day, session duration, frequency)
  - Personalization settings

### Advanced Personalization System
- **Personalized Recommendations**: Content tailored to individual preferences
- **Contextual Awareness**: Recommendations based on time of day and calendar events
- **Platform-specific Content**: Prioritized content from preferred platforms
- **Viewing Habits Integration**: Content delivery aligned with user consumption patterns

### User Interface
- **Modern, Responsive Design**: Beautiful UI with smooth animations
- **Adaptive Layout**: Optimized for various screen sizes and orientations
- **Personalized Home Screen**: Dynamic content sections based on user preferences

## Technical Architecture

### Core Services
- **OnboardingService**: Manages user preference collection and storage
- **RecommendationIntegrationService**: Connects user preferences to recommendation algorithms
- **PersonalizedRecommendationService**: Generates tailored content recommendations
- **PlatformViewRegistrationService**: Handles embedded content from various platforms

### Key Components
- **EnhancedOnboardingFlow**: Main onboarding experience controller
- **PersonalizedHomeScreen**: Primary content consumption interface
- **InterestSelectionGrid**: Visual interest selection component
- **PlatformSelectionWidget**: Platform priority configuration
- **ContentTypeSelection**: Content format preference selector
- **ViewingHabitsWidget**: Consumption pattern collection
- **PersonalizationSettingsWidget**: Advanced personalization controls

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Firebase account (for authentication and analytics)
- Supabase account (for backend services)

### Installation
1. Clone the repository
   ```
   git clone https://github.com/yourusername/afeedi.git
   ```

2. Install dependencies
   ```
   flutter pub get
   ```

3. Configure environment variables
   - Create a `.env` file based on `.env.example`
   - Add your Supabase and Firebase credentials

4. Run the application
   ```
   flutter run
   ```

## Development Roadmap

### Current Focus
- Enhanced onboarding experience
- Personalized recommendation engine
- Platform integration for content embedding

### Future Enhancements
- Social sharing capabilities
- Content creator tools and analytics
- Advanced machine learning for recommendation refinement
- Offline content caching

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.