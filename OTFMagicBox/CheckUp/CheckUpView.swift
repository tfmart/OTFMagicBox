/*
 Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.
 
 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import SwiftUI

struct CheckUpView: View {
    @StateObject var viewmodel = CheckUpViewModel()
    @State private var isPresenting = false
    
    var body: some View {
        VStack {
            Text("Check Up").font(.headerFontStyle)
                .foregroundColor(Color(YmlReader().appTheme?.headerTitleFont.color ?? .black))
                .font(YmlReader().appTheme?.headerTitleWeight.appFont ?? Font.system(size: 17.0))
                .fontWeight(YmlReader().appTheme?.textWeight.fontWeight)
            List {
                Section(header: Text("OVERALL ADHERENCE")
                    .foregroundColor(Color(YmlReader().appTheme?.headerColor.color ?? .black))) {
                    CountProgressRow(title: "Physical Activities",
                                     completed: viewmodel.activityTasksAndEvents.completedTasks.count,
                                     total: viewmodel.activityTasksAndEvents.eventsOfTasks.count,
                                     color: .blue,
                                     lineWidth: 4.0)
                        .padding(.vertical, 10.0)
                    PercentProgressRow(title: "Medications Taken",
                                       progress: Float(viewmodel.medicationTasksAndEvents.progress),
                                       color: .green,
                                       lineWidth: 4.0)
                        .padding(.vertical, 10.0)
                    PercentProgressRow(title: "Checkups",
                                       progress: Float(viewmodel.checkupTasksAndEvents.progress),
                                       color: .green,
                                       lineWidth: 4.0)
                        .padding(.vertical, 10)
                    CountProgressRow(title: "Appointments",
                                     completed: viewmodel.appointmentTasksAndEvents.completedTasks.count,
                                     total: viewmodel.appointmentTasksAndEvents.eventsOfTasks.count,
                                     color: .green,
                                     lineWidth: 4.0)
                        .padding(.vertical, 10)
                }
                .listRowBackground(Color(YmlReader().appTheme?.cellbackgroundColor.color ?? .black))
            }
            .onReceive(NotificationCenter.default.publisher(for: .deleteUserAccount)) { notification in
                isPresenting = true
            }.alert(isPresented: $isPresenting) {
                
                Alert(
                    title: Text("Account Deleted")
                        .font(YmlReader().appTheme?.textFont.appFont ?? Font.system(size: 17.0))
                        .fontWeight(YmlReader().appTheme?.textWeight.fontWeight),
                    message: Text("Your account is deleted from one of your device"),
                    dismissButton: .default(Text("Okay"), action: {
                        OTFTheraforgeNetwork.shared.moveToOnboardingView()
                    })
                )
            }
            .listStyle(GroupedListStyle())
            .onAppear {
                UITableView.appearance().separatorColor = YmlReader().appTheme?.separatorColor.color
                UITableView.appearance().backgroundColor = YmlReader().appTheme?.backgroundColor.color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewmodel.fetchTasks()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .deleteUserAccount, object: nil)
            }
        }
    }
}

struct CheckUpView_Previews: PreviewProvider {
    static var previews: some View {
        CheckUpView()
    }
}

struct ViewProvider: LibraryContentProvider {
    @LibraryContentBuilder var views: [LibraryItem] {
        LibraryItem(PercentProgressRow(title: "Row Title",
                                       progress: 0.5,
                                       color: .red,
                                       lineWidth: 4.0),
                    title: "Percent Progress Row",
                    category: .control)
        
        LibraryItem(CountProgressRow(title: "Row Title",
                                     completed: 3,
                                     total: 5,
                                     color: .red,
                                     lineWidth: 4.0),
                    title: "Count Progress Row",
                    category: .control)
        
        LibraryItem(InstructionTaskView(task: dummyTask,
                                        date: Date(),
                                        storeManager: storeManager),
                    title: "Instruction Task View",
                    category: .control)
        
        LibraryItem(GridTaskView(task: dummyTask, date: Date(),
                                 storeManager: storeManager),
                    title: "Grid Task View", category: .control)
        
        LibraryItem(SimpleTaskView(task: dummyTask, date: Date(),
                                   storeManager: storeManager),
                    title: "Simple Task View", category: .control)
        
        LibraryItem(ChecklistTaskView(task: dummyTask, date: Date(),
                                      storeManager: storeManager),
                    title: "Checklist Task View", category: .control)
        
        LibraryItem(ButtonLogTaskView(task: dummyTask, date: Date(),
                                      storeManager: storeManager),
                    title: "Button Log Task View",
                    category: .control)
    }
}
