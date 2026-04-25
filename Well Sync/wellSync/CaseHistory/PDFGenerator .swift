import UIKit
import PDFKit

struct ReportGenerator {
    
    // MARK: - Colors
    private static let tealColor  = UIColor(red: 0.0,  green: 0.50, blue: 0.50, alpha: 1.0)
    private static let mintColor  = UIColor(red: 0.60, green: 0.90, blue: 0.84, alpha: 1.0)
    private static let lightMint  = UIColor(red: 0.97, green: 1.00, blue: 0.99, alpha: 1.0)
    private static let darkText   = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
    private static let subtleGray = UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)

    static func createPDF(patient: Patient, timeline: [Timeline]) -> URL? {
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let fileName = "PatientHistory_\(patient.name.replacingOccurrences(of: " ", with: "_")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // ── Filter out missed appointments ──
        let filteredTimeline = timeline.filter { $0.title != "Missed Appointment" }
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                
                var yOffset: CGFloat = 0
                
                // MARK: - Fonts
                let titleFont        = UIFont.boldSystemFont(ofSize: 24)
                let subtitleFont     = UIFont.systemFont(ofSize: 11)
                let sectionFont      = UIFont.boldSystemFont(ofSize: 13)
                let bodyFont         = UIFont.systemFont(ofSize: 11.5)
                let boldFont         = UIFont.boldSystemFont(ofSize: 12)
                let labelFont        = UIFont.boldSystemFont(ofSize: 9.5)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                let cgContext = context.cgContext
                
                // MARK: - Helpers
                func newPageIfNeeded(height: CGFloat) {
                    if yOffset + height > pageRect.height - 60 {
                        context.beginPage()
                        yOffset = 40
                    }
                }
                
                func drawHorizontalLine(y: CGFloat, color: UIColor, width: CGFloat = 0.75) {
                    cgContext.saveGState()
                    color.setStroke()
                    cgContext.setLineWidth(width)
                    cgContext.move(to: CGPoint(x: 40, y: y))
                    cgContext.addLine(to: CGPoint(x: pageRect.width - 40, y: y))
                    cgContext.strokePath()
                    cgContext.restoreGState()
                }
                
                func drawFilledRect(_ rect: CGRect, color: UIColor, cornerRadius: CGFloat = 0) {
                    cgContext.saveGState()
                    color.setFill()
                    if cornerRadius > 0 {
                        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
                    } else {
                        cgContext.fill(rect)
                    }
                    cgContext.restoreGState()
                }
                
                // MARK: - Page Start
                context.beginPage()
                yOffset = 44
                
                // ── Title: "Patient History" in teal, centered, no background ──
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: tealColor
                ]
                let titleStr  = "Patient History" as NSString
                let titleSize = titleStr.size(withAttributes: titleAttrs)
                titleStr.draw(
                    at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yOffset),
                    withAttributes: titleAttrs
                )
                yOffset += titleSize.height + 6
                
                // Thin teal underline beneath title
                drawHorizontalLine(y: yOffset, color: tealColor, width: 1.5)
                yOffset += 20
                
                // ── Patient Info Card ──
                // Determine card height based on number of fields (2 rows: name/condition + age/gender)
//                let cardHeight: CGFloat = 72
//                let cardRect = CGRect(x: 40, y: yOffset, width: pageRect.width - 80, height: cardHeight)
//                drawFilledRect(cardRect, color: lightMint, cornerRadius: 8)
//                
//                // Teal left accent bar
//                drawFilledRect(CGRect(x: 40, y: yOffset, width: 5, height: cardHeight),
//                               color: tealColor, cornerRadius: 0)
//                
//                let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: tealColor]
//                let valueAttrs: [NSAttributedString.Key: Any] = [.font: boldFont,  .foregroundColor: darkText]
//                
//                let col1X: CGFloat = 56
//                let col2X: CGFloat = 200
//                let col3X: CGFloat = 350
//                let col4X: CGFloat = 460
//                
//                let row1Y = yOffset + 10
//                let row2Y = yOffset + 42
//                
//                // Row 1: Patient | Condition
//                "PATIENT".draw(at: CGPoint(x: col1X, y: row1Y), withAttributes: labelAttrs)
//                patient.name.draw(at: CGPoint(x: col1X, y: row1Y + 13), withAttributes: valueAttrs)
//                
//                let condValue = patient.condition ?? "N/A"
//                "CONDITION".draw(at: CGPoint(x: col2X, y: row1Y), withAttributes: labelAttrs)
//                condValue.draw(at: CGPoint(x: col2X, y: row1Y + 13), withAttributes: valueAttrs)
//                
//                // Row 2: Age | Gender
//                // -- If your Patient model has these fields swap the values below --
//                let calendar = Calendar.current
//                let ageComponents = calendar.dateComponents([.year], from: patient.dob, to: Date())
//                let ageValue = ageComponents.year != nil ? "\(ageComponents.year!) yrs" : "N/A"
//                let genderValue = patient.gender ?? "N/A"
//                
//                "AGE".draw(at: CGPoint(x: col3X, y: row1Y), withAttributes: labelAttrs)
//                ageValue.draw(at: CGPoint(x: col3X, y: row1Y + 13), withAttributes: valueAttrs)
//                
//                "GENDER".draw(at: CGPoint(x: col4X, y: row1Y), withAttributes: labelAttrs)
//                genderValue.draw(at: CGPoint(x: col4X, y: row1Y + 13), withAttributes: valueAttrs)
//                
//                // Thin divider inside card between rows
//                drawHorizontalLine(y: row2Y - 4, color: mintColor, width: 0.5)
//                
//                yOffset += cardHeight + 22
                
                // ── Patient Info Card (VERTICAL layout) ──
                let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: tealColor]
                let valueAttrs: [NSAttributedString.Key: Any] = [.font: boldFont,  .foregroundColor: darkText]

                let fields: [(label: String, value: String)] = [
                    ("PATIENT",   patient.name),
                    ("CONDITION", patient.condition ?? "N/A"),
                    ("AGE", {
                        let comps = Calendar.current.dateComponents([.year], from: patient.dob, to: Date())
                        return comps.year != nil ? "\(comps.year!) yrs" : "N/A"
                    }()),
                    ("GENDER",    patient.gender ?? "N/A")
                ]

                let rowH: CGFloat = 26
                let cardHeight = CGFloat(fields.count) * rowH + 16
                let cardRect = CGRect(x: 40, y: yOffset, width: pageRect.width - 80, height: cardHeight)
                drawFilledRect(cardRect, color: lightMint, cornerRadius: 8)

                var fieldY = yOffset + 10
                for field in fields {
                    field.label.draw(at: CGPoint(x: 56, y: fieldY), withAttributes: labelAttrs)
                    field.value.draw(at: CGPoint(x: 160, y: fieldY), withAttributes: valueAttrs)
                    fieldY += rowH
                }

                yOffset += cardHeight + 22
                
                // ── Section Header: Treatment Timeline (light mint bg, teal text) ──
                let sectionBannerHeight: CGFloat = 30
                let sectionBannerRect = CGRect(x: 40, y: yOffset,
                                               width: pageRect.width - 80,
                                               height: sectionBannerHeight)
                drawFilledRect(sectionBannerRect, color: lightMint, cornerRadius: 6)
                
                // Teal left accent bar on section header
                
                // Teal border around section header
                cgContext.saveGState()
                tealColor.withAlphaComponent(0.15).setStroke()
                UIBezierPath(roundedRect: sectionBannerRect, cornerRadius: 6).stroke()
                cgContext.restoreGState()
                
                let sectionTitle = "Treatment Timeline"
                let sectionAttrs: [NSAttributedString.Key: Any] = [
                    .font: sectionFont,
                    .foregroundColor: tealColor
                ]
                let sectionSize = (sectionTitle as NSString).size(withAttributes: sectionAttrs)
                sectionTitle.draw(
                    at: CGPoint(
                        x: (pageRect.width - sectionSize.width) / 2,
                        y: yOffset + (sectionBannerHeight - sectionSize.height) / 2
                    ),
                    withAttributes: sectionAttrs
                )
                yOffset += sectionBannerHeight + 16
                
                // MARK: - Timeline Items (missed appointments already filtered)
                for (index, item) in filteredTimeline.enumerated() {
                    
                    let dateText    = dateFormatter.string(from: item.date)
                    let dateHeight  = dateText.height(with: subtitleFont, width: 460)
                    let titleHeight = item.title.height(with: boldFont, width: 460)
                    let descHeight  = item.description.height(with: bodyFont, width: 440)
                    let totalHeight = dateHeight + titleHeight + descHeight + 32
                    
                    newPageIfNeeded(height: totalHeight)

                    
                    // Mint dot marker
                    cgContext.saveGState()
                    tealColor.withAlphaComponent(0.7).setFill()
                    let dotRect = CGRect(x: 46, y: yOffset + dateHeight + 3, width: 9, height: 9)
                    UIBezierPath(ovalIn: dotRect).fill()
                    cgContext.restoreGState()
                    
                    let contentX: CGFloat = 63
                    let contentWidth: CGFloat = pageRect.width - contentX - 50
                    
                    // DATE
                    dateText.draw(
                        in: CGRect(x: contentX, y: yOffset, width: contentWidth, height: dateHeight),
                        withAttributes: [.font: subtitleFont, .foregroundColor: subtleGray]
                    )
                    yOffset += dateHeight + 4
                    
                    // TITLE
                    item.title.draw(
                        in: CGRect(x: contentX, y: yOffset, width: contentWidth, height: titleHeight),
                        withAttributes: [.font: boldFont, .foregroundColor: tealColor]
                    )
                    yOffset += titleHeight + 6
                    
                    // DESCRIPTION
                    item.description.draw(
                        in: CGRect(x: contentX + 4, y: yOffset, width: contentWidth - 4, height: descHeight),
                        withAttributes: [.font: bodyFont, .foregroundColor: darkText]
                    )
                    yOffset += descHeight + 18
                    
                    // Separator
                    drawHorizontalLine(y: yOffset - 4, color: mintColor.withAlphaComponent(0.6))
                    yOffset += 4
                }
                
                // ── Footer ──
                let footerY = pageRect.height - 36
                drawHorizontalLine(y: footerY - 6, color: tealColor.withAlphaComponent(0.4), width: 0.5)
                let footerText = "Generated by wellSync  •  \(dateFormatter.string(from: Date()))"
                footerText.draw(
                    at: CGPoint(x: 50, y: footerY),
                    withAttributes: [.font: subtitleFont, .foregroundColor: subtleGray]
                )
            }
            
            return tempURL
            
        } catch {
            print("could not create PDF: \(error)")
            return nil
        }
    }
}

// MARK: - String Extension (unchanged)
extension String {
    func height(with font: UIFont, width: CGFloat) -> CGFloat {
        return self.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        ).height
    }
}
