//
//  CalenderCollectionViewCell.swift
//  wellSync
//
//  Created by Pranjal on 11/03/26.
//


import UIKit

protocol CalendarSelectionDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class AppointmentCalenderCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var calendarContainerView: UIView!

    weak var delegate: CalendarSelectionDelegate?
    private let calendarView = UICalendarView()

    override func awakeFromNib() {
        super.awakeFromNib()

        setupCalendar()

        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
    }

      private func setupCalendar() {

          calendarView.translatesAutoresizingMaskIntoConstraints = false

          calendarContainerView.addSubview(calendarView)

          NSLayoutConstraint.activate([
              calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
              calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
              calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
              calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
          ])

          calendarView.calendar = Calendar.current
          calendarView.locale = Locale.current
          calendarView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
      }
  }
extension AppointmentCalenderCollectionViewCell: UICalendarSelectionSingleDateDelegate {

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {

        guard let dateComponents = dateComponents else { return }

        if let date = Calendar.current.date(from: dateComponents) {

            print("Selected date:", date)

            delegate?.didSelectDate(date)

        }
    }
}

