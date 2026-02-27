//
//  NumericStepperView.swift
//  ZenForms
//
//  Created by apple on 27/02/26.
//


import UIKit

@IBDesignable
final class NumericStepperView: UIView {

    // MARK: - Outlets (XIB)

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var textField: UITextField!

    // MARK: - Public Properties

    @IBInspectable var stepValue: Double = 1
    @IBInspectable var minimumValue: Double = 0
    @IBInspectable var maximumValue: Double = 999999
    @IBInspectable var allowsDecimal: Bool = false

    var value: Double = 0 {
        didSet {
            updateText()
            onValueChanged?(value)
        }
    }

    /// Callback
    var onValueChanged: ((Double) -> Void)?
    var onEditingFinished: ((Double) -> Void)?
    // MARK: - Haptic

    private let impactFeedback =
        UIImpactFeedbackGenerator(style: .light)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}

private extension NumericStepperView {

    func commonInit() {
        let bundle = ZenFormsBundle.bundle
        bundle.loadNibNamed(
            "NumericStepperView",
            owner: self,
            options: nil
        )

        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        setupUI()
    }

    func setupUI() {

        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        clipsToBounds = true

        textField.delegate = self
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.font = .systemFont(ofSize: 16, weight: .medium)

        minusButton.setTitle("−", for: .normal)
        plusButton.setTitle("+", for: .normal)

        minusButton.titleLabel?.font =
            .systemFont(ofSize: 22, weight: .semibold)

        plusButton.titleLabel?.font =
            .systemFont(ofSize: 22, weight: .semibold)

        minusButton.addTarget(
            self,
            action: #selector(decrement),
            for: .touchUpInside
        )

        plusButton.addTarget(
            self,
            action: #selector(increment),
            for: .touchUpInside
        )

        updateText()
    }
}

private extension NumericStepperView {

    @objc func increment() {

        let newValue = min(value + stepValue, maximumValue)
        guard newValue != value else { return }

        triggerHaptic()
        animateTap()
        value = newValue
    }

    @objc func decrement() {

        let newValue = max(value - stepValue, minimumValue)
        guard newValue != value else { return }

        triggerHaptic()
        animateTap()
        value = newValue
    }
}

private extension NumericStepperView {

    func triggerHaptic() {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    func animateTap() {

        UIView.animate(withDuration: 0.12,
                       animations: {
            self.transform =
                CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                self.transform = .identity
            }
        }
    }
}

private extension NumericStepperView {

    func updateText() {
        if allowsDecimal {
            textField.text = String(value)
        } else {
            textField.text = String(Int(value))
        }
    }
}

extension NumericStepperView: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {

        guard let text = textField.text,
              let number = Double(text) else {
            updateText()
            return
        }

        let validatedValue =
            min(max(number, minimumValue), maximumValue)

        value = validatedValue

        onEditingFinished?(validatedValue)
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        let allowed = allowsDecimal
        ? CharacterSet(charactersIn: "0123456789.")
        : CharacterSet.decimalDigits

        return string.rangeOfCharacter(
            from: allowed.inverted
        ) == nil
    }
}
