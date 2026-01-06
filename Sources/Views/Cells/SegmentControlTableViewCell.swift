//
//  SegmentControlTableViewCell.swift
//  crm
//
//  Created by Mayur on 02/03/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//

import UIKit

class SegmentControlTableViewCell: UITableViewCell {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var collectionIndexPath: IndexPath?
    
    var delegate: SegmentControlDelegate?
    
    var fieldItem :FPFieldDetails?{
        didSet {
            if let _ = self.fieldItem {
                setSegmentControl()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.segmentControl.isSelected = false
        self.segmentControl.tintColor = .black
        self.segmentControl.selectedSegmentIndex = -1
    }
    
    private func setSegmentControl() {
        self.segmentControl.isSelected = false
        segmentControl.removeAllSegments()
        let radioOptions = self.fieldItem?.getRadioOptions() ?? []
        if !radioOptions.isEmpty{
            for optionIndex in radioOptions.indices {
                segmentControl.insertSegment(withTitle: radioOptions[safe:optionIndex]?["label"] as? String ?? "", at: optionIndex, animated: false)
            }
        }else{
            segmentControl.insertSegment(withTitle: FPLocalizationHelper.localize("Yes"), at: 0, animated: false)
            segmentControl.insertSegment(withTitle: FPLocalizationHelper.localize("NO"), at: 1, animated: false)
            segmentControl.insertSegment(withTitle: "N/A", at: 2, animated: false)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setSegmentControlCell(selectedSegmentIndex: Int, index: Int) {
        self.segmentControl.selectedSegmentIndex = selectedSegmentIndex
        self.segmentControl.tag = index
    }
    
    
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        self.segmentControl = sender
        self.segmentControl.tintColor = .clear
        let selectedIndex = self.segmentControl.selectedSegmentIndex
        delegate?.segmentValueChangedAt(indexPath: self.collectionIndexPath, withSelectedIndex: selectedIndex)
    }

}

protocol SegmentControlDelegate{
    func segmentValueChangedAt(indexPath index:IndexPath?, withSelectedIndex:Int)
}
