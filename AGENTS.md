# AGENTS.md — Flutter Job Portal Project Rules

## Project Context

This project is a Flutter mobile app for a job portal named Khojgar Kendra.

The app has two main user roles:

* Candidate
* Employer

The app should feel modern, clean, fast, and professional. Avoid generic AI-looking UI. Prefer polished mobile app quality.

## Main Goal

Help build a production-quality Flutter app with clean architecture, reusable widgets, safe API handling, and good UI/UX.

## Coding Rules

* Use simple, readable Flutter code.
* Do not write messy code inside one big file.
* Split screens, widgets, services, models, and providers properly.
* Prefer reusable widgets instead of repeating UI.
* Use meaningful file names and class names.
* Keep UI responsive for different screen sizes.
* Follow null safety properly.
* Do not ignore errors silently.
* Add comments only where the logic is not obvious.


## UI/UX Rules

* Design should look premium, not basic.
* Use proper spacing, padding, shadows, and border radius.
* Avoid plain empty backgrounds.
* Use soft gradients, subtle shapes, or light background patterns where suitable.
* Keep forms clean and easy to use.
* Show loading states, empty states, success states, and error states.
* Buttons should look clear and tappable.
* Text hierarchy should be strong: title, subtitle, body, caption.
* Avoid overcrowding the screen.

## Flutter State Management

Use simple state management unless the feature becomes complex.

Preferred order:

1. StatefulWidget for very small local state
2. Provider/Riverpod for shared state
3. Bloc only if the feature becomes large

## API Rules

* Keep API calls outside UI files.
* Use service classes for network requests.
* Handle loading, success, error, timeout, and no internet states.
* Never hardcode sensitive tokens.
* Store auth tokens securely.
* Do not expose private API keys in code.

## Authentication Rules

The app should support:

* Login
* Register
* Role selection
* Candidate access
* Employer access
* Protected routes
* Logout
* Token expiry handling

If user role is Candidate, do not show employer-only screens.

If user role is Employer, do not show candidate-only screens.

## Employer Side Rules

Employer features should include:

* Dashboard
* Posted jobs
* Applicant count
* Job statistics
* Quick actions
* Protected employer routes

## Candidate Side Rules

Candidate features should include:

* Job list
* Job details
* Apply job
* Applied jobs
* Profile
* Saved jobs if needed

## Error Handling Rules

Always show user-friendly messages.

Examples:

* “Something went wrong. Please try again.”
* “No internet connection.”
* “Invalid email or password.”
* “This field is required.”

Do not show raw backend errors directly to users.

## Code Review Rules

When reviewing code:

* First identify the real bug.
* Explain the issue in simple words.
* Give the corrected code.
* Mention which file to update.
* Avoid unnecessary theory.
* Do not change unrelated code.

## Performance Rules

* Avoid unnecessary rebuilds.
* Use const widgets where possible.
* Keep large widgets split into smaller widgets.
* Optimize images and assets.
* Avoid heavy logic inside build methods.

## Design Style

Preferred style:

* Modern Nepali job platform feel
* Clean cards
* Soft gradient background
* Professional blue/green accent
* Rounded corners
* Minimal but not empty
* Smooth spacing
* Human-designed look

Avoid:

* Overused AI gradients
* Too many colors
* Huge shadows
* Crowded layouts
* Plain white boring screens
* Random animations

## Response Style

When helping with this project:

* Explain in simple words.
* Give copy-paste-ready code when asked.
* Mention exact file path.
* Think like a senior Flutter developer.
* Be honest if something is wrong.
* Do not overcomplicate beginner-level fixes.
