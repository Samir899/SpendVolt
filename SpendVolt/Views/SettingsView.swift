import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var newCategoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var showingAddCategory = false
    @State private var categoryToDelete: UserCategory?
    @State private var showingDeleteAlert = false
    @State private var showingMovePaymentsSheet = false
    
    let iconOptions = [
        "tag.fill", "fuelpump.fill", "cart.fill", "bag.fill", "creditcard.fill",
        "house.fill", "bolt.fill", "drop.fill", "flame.fill", "wifi",
        "powerplug.fill", "tv.fill", "refrigerator.fill", "washer.fill",
        "fork.knife", "cup.and.saucer.fill", "heart.fill", "cross.case.fill",
        "book.fill", "graduationcap.fill", "bus.fill", "tram.fill", "bicycle",
        "car.fill", "airplane", "pawprint.fill", "tshirt.fill", "gift.fill",
        "briefcase.fill", "person.fill", "banknote.fill", "wrench.and.screwdriver.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                 
                List {
                    Section {
                        ForEach(viewModel.categories) { category in
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.primary.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: category.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.primary)
                                }
                                
                                Text(category.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.deleteCategory)
                    } header: {
                        Text("Custom Categories")
                    } footer: {
                        Text("These categories will be available when you scan a payment QR.")
                    }
                    
                    Section {
                        Button {
                            showingAddCategory = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Category")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Theme.primary)
                        }
                    }
                    
                    Section("App Information") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        NavigationLink {
                            Text("Legal information goes here...")
                                .padding()
                                .navigationTitle("Privacy Policy")
                        } label: {
                            Text("Privacy Policy")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddCategory) {
                addCategorySheet
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert, presenting: categoryToDelete) { category in
                let count = viewModel.countTransactions(for: category.name)
                
                if count > 0 {
                    Button("Move to Different Category and Delete") {
                        showingMovePaymentsSheet = true
                    }
                    Button("Just Delete (Mark Unassigned)", role: .destructive) {
                        viewModel.deleteCategory(id: category.id)
                    }
                } else {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteCategory(id: category.id)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            } message: { category in
                let count = viewModel.countTransactions(for: category.name)
                if count > 0 {
                    Text("'\(category.name)' is used in \(count) payments. You can either move these payments to another category or delete the category and mark them as 'Unassigned'.")
                } else {
                    Text("Are you sure you want to delete '\(category.name)'?")
                }
            }
            .sheet(isPresented: $showingMovePaymentsSheet) {
                if let category = categoryToDelete {
                    MovePaymentsSheet(
                        categoryToDelete: category,
                        availableCategories: viewModel.categories.filter { $0.id != category.id },
                        onMove: { targetCategoryName in
                            viewModel.deleteCategory(id: category.id, replacementCategoryName: targetCategoryName)
                            showingMovePaymentsSheet = false
                            categoryToDelete = nil
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name (e.g. Gym, Snacks)", text: $newCategoryName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 6), spacing: 15) {
                        ForEach(iconOptions, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Theme.primary : Theme.secondaryBackground)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedIcon == icon ? .white : Theme.textPrimary)
                            }
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddCategory = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCategory(name: newCategoryName, icon: selectedIcon)
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                    .disabled(newCategoryName.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct MovePaymentsSheet: View {
    @Environment(\.dismiss) var dismiss
    let categoryToDelete: UserCategory
    let availableCategories: [UserCategory]
    let onMove: (String) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Move payments from '\(categoryToDelete.name)' to:")) {
                    ForEach(availableCategories) { category in
                        Button(action: {
                            onMove(category.name)
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                .foregroundColor(Theme.primary)
                                .frame(width: 30)
                                Text(category.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        onMove("Unassigned")
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            Text("Mark as Unassigned")
                            Spacer()
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Move Payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
