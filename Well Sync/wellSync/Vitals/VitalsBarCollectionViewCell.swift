//
//  VitalsBarCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 07/02/26.
//

import UIKit
import DGCharts

protocol VitalsBarRangeNavigating: AnyObject {
    func didTapPrevBarRange(for index: Int)
    func didTapNextBarRange(for index: Int)
}


class VitalsBarCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var chartRangeLabel: UILabel!
    @IBOutlet weak var ValueLabel: UILabel!
    @IBOutlet weak var nextUnitbutton: UIButton!
    @IBOutlet weak var previousUnitButton: UIButton!
    
    private var hasAnimated = false
    
    enum DisplayRange {
        case weekly
        case monthly
    }
    weak var rangeDelegate: VitalsBarRangeNavigating?
    
    private var displayRange: DisplayRange = .weekly
    private var windowOffset: Int = 0
    
    enum MetricType {
        case sleep   // hours per day
        case steps   // steps per day
    }
    
    private var metric: MetricType = .sleep
    private var weeklyValues: [Double]?// optional injected data (7 values)
    
    var item:[(icon:String,ColorFill:UIColor)] = [
        ("powersleep",.systemIndigo),
        ("shoeprints.fill",.systemOrange)
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.cornerRadius = 16
        backgroundColor = UIColor.secondarySystemBackground
        barChartView.backgroundColor = .clear
        
    }
    func configure(index: Int,range: DisplayRange,offset: Int) {
        
        self.displayRange = range
        self.windowOffset = offset
        
        if index == 1 {
            metric = .sleep
            iconImageView.image = UIImage(systemName: item[0].icon)
            iconImageView.tintColor = item[0].ColorFill
        }
        else if index == 2 {
            metric = .steps
            iconImageView.image = UIImage(systemName: item[1].icon)
            iconImageView.tintColor = item[1].ColorFill
        }
        
        showBarChart(index: index)
    }
    
    func showBarChart(index: Int) {
        
        let calendar = Calendar.current
        let today = Date()
        
        let values: [Double]
        
        switch displayRange {
            
        case .weekly:
            switch metric {
            case .sleep:
                values = (0..<7).map { _ in Double.random(in: 4...9) }
            case .steps:
                values = (0..<7).map { _ in Double.random(in: 4000...12000) }
            }
            
        case .monthly:
            switch metric {
            case .sleep:
                values = (0..<4).map { _ in Double.random(in: 30...60) }
            case .steps:
                values = (0..<4).map { _ in Double.random(in: 40000...80000) }
            }
        }
        
        let maxValue = max(values.max() ?? 1, 1)
        var labels: [String] = []
        
        switch displayRange {
            
        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let target = calendar.date(byAdding: .weekOfYear, value: windowOffset, to: start)!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: i, to: target)!
                labels.append(formatter.string(from: date))
            }
            
        case .monthly:
            labels = ["W1","W2","W3","W4"]
        }
        switch displayRange {
            
        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: today)!.start
            let target = calendar.date(byAdding: .weekOfYear, value: windowOffset, to: start)!
            let end = calendar.date(byAdding: .day, value: 6, to: target)!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            
            chartRangeLabel.text = "\(formatter.string(from: target)) – \(formatter.string(from: end))"
            
            
        case .monthly:
            let start = calendar.dateInterval(of: .month, for: today)!.start
            let target = calendar.date(byAdding: .month, value: windowOffset, to: start)!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            
            chartRangeLabel.text = formatter.string(from: target)
        }
        
        var fgEntries: [BarChartDataEntry] = []
        var bgEntries: [BarChartDataEntry] = []
        
        for i in 0..<values.count {
            fgEntries.append(.init(x: Double(i), y: values[i]))
            bgEntries.append(.init(x: Double(i), y: maxValue))
        }
        
        let fgColor = item[index].ColorFill
        let bgColor = fgColor.withAlphaComponent(0.12)
        
        let fgSet = BarChartDataSet(entries: fgEntries, label: "")
        fgSet.colors = [fgColor]
        fgSet.drawValuesEnabled = false
        fgSet.highlightEnabled = false
        
        let bgSet = BarChartDataSet(entries: bgEntries, label: "")
        bgSet.colors = [bgColor]
        bgSet.drawValuesEnabled = false
        bgSet.highlightEnabled = false
        
        let data = BarChartData(dataSets: [bgSet, fgSet])
        data.barWidth = 0.65
        
        barChartView.data = data
        
        barChartView.legend.enabled = false
        barChartView.chartDescription.enabled = false
        barChartView.doubleTapToZoomEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.setScaleEnabled(false)
        
        barChartView.leftAxis.enabled = false
        barChartView.rightAxis.enabled = false
        
        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.labelTextColor = .secondaryLabel
        xAxis.granularity = 1
        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        
        barChartView.setExtraOffsets(left: 12, top: 12, right: 12, bottom: 6)
        
        if !hasAnimated {
            barChartView.animate(yAxisDuration: 1.0)
            hasAnimated = true
        }
    }
    
    @IBAction func nextRangeTapped(_ sender: UIButton) {
        rangeDelegate?.didTapNextBarRange(for: metric == .sleep ? 1 : 2)
        
    }
    
    @IBAction func prevRangeTapped(_ sender: UIButton) {
        rangeDelegate?.didTapPrevBarRange(for: metric == .sleep ? 1 : 2)
    }
}
