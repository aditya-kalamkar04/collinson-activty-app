# Location Activities

An iOS app that takes a city or town and ranks how good the next 7 days look for skiing, surfing, outdoor sightseeing and indoor sightseeing. Weather comes from Open-Meteo's Geocoding and Forecast APIs. There's no backend and no API key.

My reasoning, assumptions and trade-offs are in [DECISIONS.md](DECISIONS.md). That's the part I'd read first.

## What it does

1. Search for a place. Results come up as you type (debounced, and stale responses are dropped), each with its region and country so you can tell the different Londons apart.
2. Tap a result to see the four activities ranked best first. Each one shows:
   - a 0–100 score for the week and a rating (Excellent / Good / Fair / Poor)
   - its best day, with a one-line reason ("12 cm fresh snow, high of -3°")
   - seven bars showing how the week shapes up

Loading, empty, offline and server-error states are all handled, with retry and pull-to-refresh.

## Running it

Requirements: Xcode 16 or later (Swift 6, Swift Testing) and iOS 17+.

1. Open `LocationActivities.xcworkspace`.
2. Wait a few seconds while Xcode resolves the local `LocationActivitiesKit` package.
3. Select the `LocationActivities` scheme and an iPhone simulator, then press Run (⌘R).

The simulator needs no signing setup. To run on a physical device, choose your team under Signing & Capabilities.

The project uses Xcode 16's folder-synchronised groups. Any Swift file you add under `App/` is picked up automatically, so `project.pbxproj` rarely changes and stays easy to review.

## Running the tests

Everything except the SwiftUI views lives in a local Swift package, so the tests run without a simulator:

```bash
cd Packages/LocationActivitiesKit
swift test
```

You can also press ⌘U in Xcode. The `LocationActivities` scheme's test action runs the package's test suites.

## Project layout

```
LocationActivities.xcworkspace           open this
LocationActivities.xcodeproj             app target + local package reference + shared scheme
App/                                   SwiftUI app target (thin)
  LocationActivitiesApp.swift            entry point
  DI/AppContainer.swift                composition root, injected via Environment
  Features/CitySearch/                 search screen
  Features/ActivityRanking/            ranking screen, card, daily row
  Common/Components/                   LoadableView, ErrorStateView, ScoreBadge, ScoreBarsView
  Common/Styling/                      SF Symbols and colours for domain types
  PreviewSupport/                      offline fakes for SwiftUI previews

Packages/LocationActivitiesKit/
  Sources/LocationActivitiesKit/
    Models/                            City, DailyForecast, Activity, WeatherCondition, ActivityReport
    Domain/
      Repositories/                    protocols the domain depends on
      UseCases/                        SearchCities, RankActivities
      Scoring/                         one scorer per activity + shared ScoreCurve maths
    Services/
      Networking/                      HTTPClient, Endpoint, APIClient, NetworkError
      OpenMeteo/                       geocoding + forecast services, DTOs, mapper
      Cache/                           CachedForecastRepository (actor)
    Features/                          @Observable view models
    Common/                            ViewState, UserFacingError, DayLabelFormatter
  Tests/LocationActivitiesKitTests/      Swift Testing suites + test doubles
```

## Main assumptions

- "Rank" means comparing the four activities against each other for the place you picked, using a 0–100 score per day averaged over the week.
- Surfing is rated on the weather only (wind, warmth, rain, sun). The Forecast API has no wave data and we can't tell whether a place is on the coast. This is the biggest limitation, and the first thing I'd change (see DECISIONS.md).
- Skiing can't see the existing snow base, only new snowfall and temperature.
- Indoor sightseeing is always possible, so it never scores below about 50, and it gets better as the outdoor weather gets worse.
- Metric units throughout, pinned in the request.
- Days are shown in the destination's time zone, not the device's.
