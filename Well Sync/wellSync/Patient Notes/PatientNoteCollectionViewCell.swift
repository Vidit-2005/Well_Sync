//
//  PatientNoteCollectionViewCell.swift
//  wellSync
//
//  Created by Rishika Mittal on 13/03/26.
//

import UIKit

class PatientNoteCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var noteNumber: UILabel!
    @IBOutlet weak var noteDate: UILabel!
    @IBOutlet weak var note: UILabel!
    func configure(with patient: PatientNote,index:Int)
    {
        noteNumber.text = "Note \(index)"
        note.text = patient.note
        noteDate.text = patient.date.formatted(date: .numeric, time: .omitted)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)
    }
}
