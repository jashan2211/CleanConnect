// InputValidation.swift
// Form validation helpers and UI components

import SwiftUI
import UIKit

// MARK: - Validation Rules

enum ValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case numeric
    case positiveNumber
    case range(Double, Double)
    case url
    case custom((String) -> Bool, String)

    func validate(_ value: String) -> ValidationResult {
        switch self {
        case .required:
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? .invalid("This field is required")
                : .valid

        case .minLength(let min):
            return value.count < min
                ? .invalid("Must be at least \(min) characters")
                : .valid

        case .maxLength(let max):
            return value.count > max
                ? .invalid("Must be no more than \(max) characters")
                : .valid

        case .numeric:
            return Double(value) == nil && !value.isEmpty
                ? .invalid("Must be a valid number")
                : .valid

        case .positiveNumber:
            guard let num = Double(value) else {
                return value.isEmpty ? .valid : .invalid("Must be a valid number")
            }
            return num <= 0 ? .invalid("Must be greater than 0") : .valid

        case .range(let min, let max):
            guard let num = Double(value) else {
                return value.isEmpty ? .valid : .invalid("Must be a valid number")
            }
            return (num < min || num > max)
                ? .invalid("Must be between \(Int(min)) and \(Int(max))")
                : .valid

        case .url:
            if value.isEmpty { return .valid }
            guard let url = URL(string: value),
                  url.scheme != nil else {
                return .invalid("Must be a valid URL")
            }
            return .valid

        case .custom(let validator, let message):
            return validator(value) ? .valid : .invalid(message)
        }
    }
}

enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

// MARK: - Validated Text Field

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let rules: [ValidationRule]
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal

    @State private var hasBeenEdited = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onChange(of: text) { _, _ in
                    hasBeenEdited = true
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        hasBeenEdited = true
                    }
                }

            if hasBeenEdited, let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validationError)
    }

    private var validationError: String? {
        for rule in rules {
            let result = rule.validate(text)
            if let error = result.errorMessage {
                return error
            }
        }
        return nil
    }

    var isValid: Bool {
        validationError == nil
    }
}

// MARK: - Validation State Helper

@MainActor
class FormValidator: ObservableObject {
    @Published var fields: [String: ValidationResult] = [:]

    func validate(_ value: String, for field: String, rules: [ValidationRule]) -> Bool {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                fields[field] = result
                return false
            }
        }
        fields[field] = .valid
        return true
    }

    func error(for field: String) -> String? {
        fields[field]?.errorMessage
    }

    var isFormValid: Bool {
        fields.values.allSatisfy { $0.isValid }
    }

    func reset() {
        fields.removeAll()
    }
}

// MARK: - Video URL Validation

extension ValidationRule {
    static var videoURL: ValidationRule {
        .custom({ value in
            if value.isEmpty { return true }
            let lowercased = value.lowercased()
            return lowercased.contains("youtube.com") ||
                   lowercased.contains("youtu.be") ||
                   lowercased.contains("instagram.com/reel") ||
                   lowercased.contains("instagram.com/p/")
        }, "Must be a YouTube or Instagram URL")
    }
}
