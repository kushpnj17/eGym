//
//  HomeVM.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import FirebaseFirestore
import FirebaseFunctions
import Foundation

private let dayOrder: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private func ordered(_ days: [DayPlan]) -> [DayPlan] {
  days.sorted { (a, b) in
    (dayOrder.firstIndex(of: a.day) ?? 0) < (dayOrder.firstIndex(of: b.day) ?? 0)
  }
}

final class HomeVM2: ObservableObject {
  @Published var plan: WorkoutPlan?
  @Published var today: DayPlan?
  @Published var loading = false
  @Published var error: String?

  // 🔸 NEW: keep all workout plans for this user (for the dropdown)
  @Published var allPlans: [WorkoutPlan] = []

  // MARK: - Load current active plan

  func load(uid: String) {
    loading = true
    error = nil
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    userRef.getDocument { snap, err in
      if let err = err {
        self.error = err.localizedDescription
        self.loading = false
        return
      }
      guard let data = snap?.data(),
            let activeId = data["activePlanId"] as? String, !activeId.isEmpty
      else {
        self.loading = false
        return
      }

      db.collection("users").document(uid)
        .collection("workoutPlans").document(activeId)
        .getDocument(as: WorkoutPlan.self) { result in
          switch result {
          case .failure(let e):
            self.error = e.localizedDescription
          case .success(let plan):
            self.plan = plan
            self.today = self.pickToday(from: plan, userData: data)

            // 🔸 NEW: once we know things are wired, also load *all* plans
            self.loadAllPlans(uid: uid)
          }
          self.loading = false
        }
    }
  }

  // 🔸 NEW: load every plan in users/{uid}/workoutPlans (for the dropdown)

  private func loadAllPlans(uid: String) {
    let db = Firestore.firestore()
    db.collection("users")
      .document(uid)
      .collection("workoutPlans")
      .order(by: "createdAt", descending: false)
      .getDocuments { snapshot, error in
        if let error = error {
          print("Failed to load all plans:", error)
          return
        }
        guard let docs = snapshot?.documents else { return }

        do {
          self.allPlans = try docs.map { doc in
            try doc.data(as: WorkoutPlan.self)
          }
        } catch {
          print("Decoding all plans failed:", error)
        }
      }
  }

  // MARK: - Generate a plan on demand (called from HomeView button)

  @MainActor
  func generatePlan(uid: String) async {
    loading = true
    error = nil

    let functions = Functions.functions()

    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    do {
      // 1) Call the Cloud Function: generateWorkoutPlan
      let callable = functions.httpsCallable("generateWorkoutPlan")
      callable.timeoutInterval = 90    // timeout overridden to 90 seconds
      let result = try await callable.call([:])

      // 2) Extract workoutPlanId from the response
      guard let dict = result.data as? [String: Any],
            let planId = dict["workoutPlanId"] as? String
      else {
        throw NSError(
          domain: "HomeVM",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Invalid response from generateWorkoutPlan."]
        )
      }

      // 3) Set this plan as active on the user doc
      try await userRef.setData(
        [
          "activePlanId": planId,
          "planStartWeekday": "Mon",
          "updatedAt": FieldValue.serverTimestamp(),
        ],
        merge: true
      )

      // 4) Fetch the plan document we just created
      let planSnap =
        try await userRef
          .collection("workoutPlans")
          .document(planId)
          .getDocument()

      guard planSnap.exists else {
        throw NSError(
          domain: "HomeVM",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Workout plan document not found."]
        )
      }

      let plan = try planSnap.data(as: WorkoutPlan.self)

      // 5) Compute "today"
      self.plan = plan
      self.today = self.pickToday(
        from: plan,
        userData: ["planStartWeekday": "Mon"]
      )

      // 🔸 NEW: refresh the full list including this new plan
      self.loadAllPlans(uid: uid)

      self.loading = false
    } catch {
      if let err = error as NSError?,
         err.domain == FunctionsErrorDomain,
         FunctionsErrorCode(rawValue: err.code) == .deadlineExceeded
      {
        // Cloud Function took too long, but it may still have created a plan.
        print("Deadline exceeded – trying to reload any active plan from Firestore.")

        // Keep loading state while we try to recover
        self.error = nil

        // Try to pull whatever is now active on the user doc
        self.load(uid: uid)
        return  // IMPORTANT: don't fall through and set an error message
      }

      // For real errors, surface them in the UI
      if let err = error as NSError? {
        print("Functions error:", err.domain, err.code, err.userInfo)
      } else {
        print("Functions error (non-NS):", error)
      }

      self.error = error.localizedDescription
      self.loading = false
    }
  }

  // 🔸 NEW: allow switching which plan is active from the dropdown

  @MainActor
  func setActivePlan(_ plan: WorkoutPlan, uid: String) async {
    guard let planId = plan.id else { return }

    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    do {
      try await userRef.setData(
        [
          "activePlanId": planId,
          "planStartWeekday": "Mon",
          "updatedAt": FieldValue.serverTimestamp(),
        ],
        merge: true
      )

      self.plan = plan
      self.today = self.pickToday(
        from: plan,
        userData: ["planStartWeekday": "Mon"]
      )
    } catch {
      print("Failed to set active plan:", error)
      self.error = error.localizedDescription
    }
  }

  // MARK: - Helper

  private func pickToday(from plan: WorkoutPlan, userData: [String: Any]) -> DayPlan? {
    let calendar = Calendar.current
    let dowSymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let todaySymbol = dowSymbols[calendar.component(.weekday, from: Date()) - 1]
    let start = (userData["planStartWeekday"] as? String) ?? "Mon"
    let order: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let offset = (order.firstIndex(of: todaySymbol) ?? 0) - (order.firstIndex(of: start) ?? 0)
    let idx = (offset % 7 + 7) % 7
    let todayKey = order[idx]
    return plan.week.first { $0.day == todayKey } ?? plan.week.first
  }
}
