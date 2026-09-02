import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HomeView: View {
  @EnvironmentObject var auth: AuthViewModel
  @EnvironmentObject var vm: HomeVM   // shared VM, injected from root

  @State private var didFinishQuestionnaire = false
  @State private var showWeeklyPlan = false
  @State private var showPlanPicker = false

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    NavigationStack {
      ScrollView(showsIndicators: false) {
        VStack(spacing: 16) {

          // ---------- HEADER ----------
          VStack(spacing: 4) {
            Text("Welcome back, \(displayName) 👋")
              .font(.largeTitle).bold()
              .foregroundColor(Palette.textPrimary)
              .multilineTextAlignment(.center)

            Text("What should we work on today?")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 4)
          .padding(.horizontal, 24)

          // ---------- TODAY CARD / STATE ----------
          ZStack {
            if vm.loading {
              LLMGeneratingView(
                title: "Generating your weekly plan…",
                subtitle: "This could take up to a minute."
              )
              .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let day = vm.today, let plan = vm.plan {
              TodayCard(day: day, planName: plan.name)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if vm.error != nil {
              ErrorCard(text: vm.error ?? "Something went wrong")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
              EmptyCard()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(minHeight: 270)
          .padding(.horizontal, 24)

          // ---------- INLINE PLAN CONTROLS (UNIFORM BUTTONS) ----------
          if let plan = vm.plan {

            // Hidden NavigationLink for programmatic nav
            NavigationLink(
              destination: WeeklyPlanView(plan: plan),
              isActive: $showWeeklyPlan
            ) {
              EmptyView()
            }
            .hidden()

            HStack(spacing: 12) {

              // Switch plan – shakable when "disabled"
              if !vm.allPlans.isEmpty {
                ShakablePlanButton(disabled: vm.loading) {
                  showPlanPicker = true
                } label: {
                  PlanActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Switch plan",
                    filled: false
                  )
                }
                .confirmationDialog("Switch plan", isPresented: $showPlanPicker) {
                  if let uid = auth.user?.uid {
                    ForEach(vm.allPlans) { p in
                      Button {
                        Task {
                          await vm.setActivePlan(p, uid: uid)
                        }
                      } label: {
                        if let currentId = vm.plan?.id, currentId == p.id {
                          Text("\(p.name) ✓")
                        } else {
                          Text(p.name)
                        }
                      }
                    }
                  }
                }
              }

              // View current plan – shakable while loading
              ShakablePlanButton(disabled: vm.loading) {
                showWeeklyPlan = true
              } label: {
                PlanActionButton(
                  icon: "calendar",
                  text: "View current plan",
                  filled: true
                )
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
          }

          // ---------- GENERATE PLAN BUTTON (same component, full width) ----------
          if let uid = auth.user?.uid {
            ShakablePlanButton(disabled: vm.loading) {
              Task { await vm.generatePlan(uid: uid) }
            } label: {
              PlanActionButton(
                icon: "wand.and.stars",
                text: vm.loading ? "Generating plan..." : "Generate my weekly plan",
                filled: true
              )
            }
            .padding(.horizontal, 24)
          }

          // ---------- STRENGTH RATING ----------
          StrengthRatingCard()
            .padding(.horizontal, 24)

          // (Sign out removed – moved to account page)
        }
        .padding(.bottom, 32)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink {
            ProfileView(didFinishQuestionnaire: $didFinishQuestionnaire)
          } label: {
            Image(systemName: "person.crop.circle")
              .font(.system(size: 22, weight: .semibold))
              .foregroundColor(Palette.textPrimary)
          }
        }
      }
      // react to auth user changes to clear/load HomeVM
      .onAppear {
        vm.handleAuthChange(auth.user?.uid)
      }
      .onChange(of: auth.user?.uid) { newUID in
        vm.handleAuthChange(newUID)
      }
    }
    .egymBackground()
  }
}

#Preview {
  HomeView()
    .environmentObject(AuthViewModel())
    .environmentObject(HomeVM())
}
