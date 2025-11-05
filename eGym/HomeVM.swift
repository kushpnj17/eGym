//
//  HomeVM.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import Foundation
import FirebaseFirestore

private let dayOrder: [String] = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
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
        loading = true; error = nil
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { snap, err in
            if let err = err { self.error = err.localizedDescription; self.loading = false; return }
            guard let data = snap?.data(),
                  let activeId = data["activePlanId"] as? String, !activeId.isEmpty else {
                self.loading = false; return
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

    private func pickToday(from plan: WorkoutPlan, userData: [String: Any]) -> DayPlan? {
        let calendar = Calendar.current
        let dowSymbols = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let todaySymbol = dowSymbols[calendar.component(.weekday, from: Date()) - 1]
        let start = (userData["planStartWeekday"] as? String) ?? "Mon"
        let order: [String] = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let offset = (order.firstIndex(of: todaySymbol) ?? 0) - (order.firstIndex(of: start) ?? 0)
        let idx = (offset % 7 + 7) % 7
        let todayKey = order[idx]
        return plan.week.first { $0.day == todayKey } ?? plan.week.first
    }
}
