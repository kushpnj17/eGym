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

final class HomeVM: ObservableObject {
  @Published var plan: WorkoutPlan?
  @Published var today: DayPlan?
  @Published var loading = false
  @Published var error: String?

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
          }
          self.loading = false
        }
    }
  }

  // MARK: - NEW: Generate a plan on demand (called from HomeView button)

    // MARK: - NEW: Generate a plan on demand (called from HomeView button)

@MainActor
func generatePlan(uid: String) async {
  loading = true
  error = nil

  let functions = Functions.functions()
  let db = Firestore.firestore()
  let userRef = db.collection("users").document(uid)

  do {
    // 1) Call the Cloud Function: generateWorkoutPlan
    //    No data needed in the body; it uses request.auth.uid on the server.
    let result = try await functions.httpsCallable("generateWorkoutPlan").call([:])

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
    let planSnap = try await userRef
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

    // 5) Compute "today" using your existing helper
    self.plan = plan
    self.today = self.pickToday(from: plan,
                                userData: ["planStartWeekday": "Mon"])

    self.loading = false
  } catch {
    if let err = error as NSError? {
      print("Functions error:", err.domain, err.code, err.userInfo)

      // Try to show server-side details (what we pass from HttpsError)
      if let details = err.userInfo[FunctionsErrorDetailsKey] as? String {
        self.error = details
      } else if let desc = err.userInfo[NSLocalizedDescriptionKey] as? String {
        self.error = desc
      } else {
        self.error = err.localizedDescription
      }
    } else {
      print("Functions error (non-NS):", error)
      self.error = error.localizedDescription
    }

    self.loading = false
  }
}


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
