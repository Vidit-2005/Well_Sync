//
//  LoginViewController.swift
//  wellSync
//
//  Created by Rishika Mittal on 04/02/26.
//

import UIKit

class LoginViewController: UIViewController {

    let gradient = CAGradientLayer()

    @IBOutlet weak var userName:  UITextField!
    @IBOutlet weak var passWord:  UITextField!
    @IBOutlet weak var glassView: UIView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupActivityIndicator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = view.bounds

        glassView.layer.cornerRadius  = 50
        glassView.layer.borderWidth   = 1
        glassView.layer.borderColor   = UIColor.white.withAlphaComponent(0.8).cgColor
        glassView.layer.shadowColor   = UIColor.black.cgColor
        glassView.layer.shadowOpacity = 0.15
        glassView.layer.shadowRadius  = 20
        glassView.layer.shadowOffset  = CGSize(width: 0, height: 10)
    }

    private func setupGradient() {
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 113/255, green: 201/255, blue: 206/255, alpha: 1).cgColor,
            UIColor.white.cgColor
        ]
        gradient.locations  = [0.0, 0.5]
        gradient.startPoint = CGPoint(x: 1, y: 0.0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        
        view.layer.insertSublayer(gradient, at: 0)
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemCyan
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }

    @IBAction func registerDoctor(_ sender: UIButton) {
        performSegue(withIdentifier: "register", sender: nil)
    }
    @IBAction func loginButton(_ sender: UIButton) {

        guard let email    = userName.text, !email.isEmpty,
              let password = passWord.text, !password.isEmpty else {
            showAlert(message: "Please enter email and password.")
            return
        }

        setLoading(true)

        Task {
            do {
                let authID = try await SupabaseManager.shared.signIn(
                    email: email, password: password)

                let role = try await SupabaseManager.shared.resolveRole(authID: authID)

                switch role {

                case .doctor:
                    let doctor = try await AccessSupabase.shared.fetchDoctorByAuthID(authID)
                    SessionManager.shared.currentDoctor = doctor
                    SessionManager.shared.saveSession(role: .doctor, doctorID: doctor.docID)

                    await MainActor.run {
                        self.setLoading(false)
                        self.sceneDelegate?.showDoctorDashboard(doctor: doctor)
                    }

                case .patient:
                    let patient = try await AccessSupabase.shared.fetchPatientByAuthID(authID)
                    SessionManager.shared.currentPatient = patient
                    SessionManager.shared.saveSession(role: .patient,
                                                      patientID: patient.patientID)

                    await MainActor.run {
                        self.setLoading(false)
                        self.sceneDelegate?.showPatientDashboard(patient: patient)
                    }

                case .none:
                    await MainActor.run {
                        self.setLoading(false)
                        self.showAlert(message: "Account not found.")
                    }
                }

            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showAlert(message: "Login failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private var sceneDelegate: SceneDelegate? {
        UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
