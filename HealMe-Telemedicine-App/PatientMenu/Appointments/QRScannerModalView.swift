//
//  QRScannerModalView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct QRScannerModalView: View {
    let appointment: Appointment?
    let onQRScanned: (Appointment?) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing: Bool = false

    private let colors = (
        green: Color(hex: "28A745"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Validar Cita")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 16)

                Text("Escanea el código QR para confirmar tu cita")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if appointment == nil {
                    Text("Error: No se proporcionó una cita válida")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button(action: {
                    isProcessing = true
                    print("QR code scanned (simulated), appointment: \(String(describing: appointment))")
                    onQRScanned(appointment)
                }) {
                    Text(isProcessing ? "Procesando..." : "Escanear Código QR")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? colors.green.opacity(0.5) : colors.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .disabled(isProcessing || appointment == nil)

                Button(action: {
                    dismiss()
                }) {
                    Text("Cancelar")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                }
                .disabled(isProcessing)
            }
        }
        .onAppear {
            print("QRScannerModalView appeared with appointment: \(String(describing: appointment))")
        }
    }
}

struct QRScannerModalView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerModalView(appointment: nil) { _ in }
    }
}
