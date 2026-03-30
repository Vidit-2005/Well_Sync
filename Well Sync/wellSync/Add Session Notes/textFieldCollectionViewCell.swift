import UIKit

protocol TextFieldCollectionViewCellDelegate: AnyObject {
    func textFieldCell(_ cell: textFieldCollectionViewCell, didChangeHeight height: CGFloat)
}

class textFieldCollectionViewCell: UICollectionViewCell, UITextViewDelegate {

    @IBOutlet weak var writtenNote: UITextView!
    @IBOutlet weak var writtenNoteHeightConstraint: NSLayoutConstraint!

    weak var delegate: TextFieldCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        writtenNote.delegate = self
        writtenNote.isScrollEnabled = false
        writtenNote.backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextViewHeight()
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
    }

    private func updateTextViewHeight() {
        let targetSize = CGSize(width: writtenNote.bounds.width, height: .greatestFiniteMagnitude)
        let newSize = writtenNote.sizeThatFits(targetSize)

        if abs(writtenNoteHeightConstraint.constant - newSize.height) > 0.5 {
            writtenNoteHeightConstraint.constant = newSize.height
            delegate?.textFieldCell(self, didChangeHeight: newSize.height)
        }
    }
}
