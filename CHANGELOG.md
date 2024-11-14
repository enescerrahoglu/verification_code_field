## 1.0.7

- **`onChanged` callback**: Introduced the `onChanged` property, which triggers a callback function whenever the user initiates a change in the TextField's value, whether through insertion or deletion. This addition allows for real-time handling of input updates.

## 1.0.6

- **`cleanAllAtOnce` property**: Added the `cleanAllAtOnce` option. When enabled, a single deletion gesture clears all fields and focuses on the first field. This feature enhances user convenience by allowing quick resets.
- **`tripleSeparated` property**: Introduced the `tripleSeparated` option, which divides 6-digit fields into two groups of three, separated by additional spacing. This layout improves readability for certain verification code formats.

## 1.0.5

- Added focusedBorder property.

## 1.0.1

- Documentation added.

## 1.0.0

- Support for 4, 5, or 6-digit codes.
- Enabled automatic focus navigation between fields.
- Customization for text style, cursor color, fill color and more.
- `onSubmit` callback to capture complete code on entry.
- Limited input to digits only.
