//
//  SceneDelegate.swift
//  Project
//
//  Created by Vidit Saran Agarwal on 26/01/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let hasSeenAppOnboardingKey = "has_seen_app_onboarding"
    private let splashDisplayDuration: TimeInterval = 0.45

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create the window
        window = UIWindow(windowScene: windowScene)

        showSplashAndRoute()
    }
    
    // MARK: - Session Check on App Launch
    @MainActor
    private func checkAndRestoreSession() async {

        // Step 1: Ask Supabase for the current device-level auth session
        guard let authID = await SupabaseManager.shared.getCurrentAuthUserID() else {
            showLoginScreen()
            return
        }

        // ── SINGLE-TRUTH GUARD ──────────────────────────────────────────────────
        // If SessionManager already knows who the real user is, verify that
        // Supabase's current session matches. A patient signup will have swapped
        // the Supabase session to the patient — catch that here and evict it.
        if let persistedAuthID = SessionManager.shared.persistedAuthID,
           authID.uuidString.lowercased() != persistedAuthID.lowercased() {

            print("⚠️ Session mismatch detected. Supabase auth belongs to a different user. Signing out rogue session.")
            await SupabaseManager.shared.signOutSilently()
            showLoginScreen()
            return
        }
        // ────────────────────────────────────────────────────────────────────────

        // Step 2: Valid + matching auth session — resolve role as before
        do {
            let role = try await SupabaseManager.shared.resolveRole(authID: authID)

            switch role {
            case .doctor:
                let doctor = try await AccessSupabase.shared.fetchDoctorByAuthID(authID)
                SessionManager.shared.currentDoctor = doctor
                SessionManager.shared.saveSession(
                    role:     .doctor,
                    authID:   authID,          // ← persist authID
                    doctorID: doctor.docID
                )
                showDoctorDashboard(doctor: doctor)

            case .patient:
                let patient = try await AccessSupabase.shared.fetchPatientByAuthID(authID)
                SessionManager.shared.currentPatient = patient
                SessionManager.shared.saveSession(
                    role:      .patient,
                    authID:    authID,         // ← persist authID
                    patientID: patient.patientID
                )
                showPatientDashboard(patient: patient)

            case .none:
                showLoginScreen()
            }
        } catch {
            print("Session restore failed: \(error)")
            showLoginScreen()
        }
    }
    
    private func showSplashAndRoute() {
        let splashStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let splashVC = splashStoryboard.instantiateInitialViewController() ?? UIViewController()

        setRootViewController(splashVC, animated: false)
        window?.makeKeyAndVisible()

        DispatchQueue.main.asyncAfter(deadline: .now() + splashDisplayDuration) { [weak self] in
            guard let self else { return }

            if self.shouldShowAppOnboarding() {
                self.showOnboardingScreen()
            } else {
                Task {
                    await self.checkAndRestoreSession()
                }
            }
        }
    }

    private func showOnboardingScreen() {
        let storyboard = UIStoryboard(name: "WellSyncOnboarding", bundle: nil)

        guard let onboardingVC = storyboard.instantiateInitialViewController()
                as? WellSyncOnboardingViewController else {
            Task { await checkAndRestoreSession() }
            return
        }

        onboardingVC.onFinish = { [weak self] in
            Task { @MainActor in
                self?.markAppOnboardingSeen()
                await self?.checkAndRestoreSession()
            }
        }

        setRootViewController(onboardingVC, animated: true)
    }
    // MARK: - Navigation Helpers
    private func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let nav = storyboard.instantiateInitialViewController()!
        
        setRootViewController(nav, animated: true)
    }
    
    func showDoctorDashboard(doctor: Doctor) {
     
            let rootVC = UIStoryboard(name: "DoctorFrontPage", bundle: nil)
                .instantiateViewController(withIdentifier: "doctor")
     
            // The "doctor" storyboard root is usually a UINavigationController.
            // Walk the hierarchy to find HomeCollectionViewController and pass the doctor.
        if let nav = rootVC as? UINavigationController,
                   let home = nav.viewControllers.first as? HomeCollectionViewController {
                    home.doctor = doctor
                }
        setRootViewController(rootVC, animated: true)
        }
    
    func showPatientDashboard(patient: Patient) {
        let storyboard = UIStoryboard(name: "Patient_Dashboard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Patient") as! TabBar
        vc.patient = patient
        setRootViewController(vc, animated: true)
    }

    private func shouldShowAppOnboarding() -> Bool {
        !UserDefaults.standard.bool(forKey: hasSeenAppOnboardingKey)
    }

    private func markAppOnboardingSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenAppOnboardingKey)
    }

    private func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        guard let window else { return }

        if animated, window.rootViewController != nil {
            UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve]) {
                let animationsEnabled = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                window.rootViewController = viewController
                UIView.setAnimationsEnabled(animationsEnabled)
            }
        } else {
            window.rootViewController = viewController
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
