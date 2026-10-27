# Weather App

One sentence about your app. My data is now saved on the phone with shared_preferences,
so nothing is lost when the app closes, and it shows the live current weather in Kigali
from the Open-Meteo API.

## Features
- Fetches live temperature, feels-like, humidity and wind speed for Kigali from the
  Open-Meteo API, with a day/night and condition-based icon.
- The last weather fetched is cached with `shared_preferences`, so on the next launch
  (even with no internet) the screen shows that saved weather immediately instead of
  a blank loading state.
- If a background refresh fails (no internet), the app keeps showing the saved weather
  with a notice and a Retry button, instead of losing what was on screen.
- If there is no saved weather yet and the first load fails, a full error screen with
  a Retry button is shown.
- Pull to refresh re-fetches the weather manually.

## Screenshots
![Before closing](screenshots/before.png)
![After running again](screenshots/after.png)
![Live data from an API](screenshots/api.png)
![No internet](screenshots/no-internet.png)

## Project structure
```
lib/
  data/WeatherModel.dart   # Weather model + API fetch (Open-Meteo)
  data/WeatherStore.dart   # shared_preferences cache (save/load last weather)
  presendation/WeatherApp.dart  # screen: loading, cached, live, offline and error states
  main.dart
```
