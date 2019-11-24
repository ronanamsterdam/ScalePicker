//
//  SlidePicker.swift
//  Dmitry Klimkin
//
//  Created by Dmitry Klimkin on 12/11/15.
//  Copyright © 2016 Dmitry Klimkin. All rights reserved.
//

import Foundation
import UIKit

public protocol SlidePickerDelegate {
    func didSelectValue(value: CGFloat)
}

@IBDesignable
public class SlidePicker: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    public var delegate: SlidePickerDelegate?
    
    @IBInspectable
    public var snapEnabled: Bool = true
    
    @IBInspectable
    public var showTickLabels: Bool = true {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBInspectable
    public var highlightCenterTick: Bool = false
    
    @IBInspectable
    public var bounces: Bool = false {
        didSet {
            collectionView.bounces = bounces
        }
    }
    
    @IBInspectable
    public var spaceBetweenTicks: CGFloat = 20.0 {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBInspectable
    public var centerViewOffsetY: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }

    private let cellId = "collectionViewCellId"

    private var flowLayout = SlidePickerFlowLayout()
    private var collectionView: UICollectionView!
    private var tickValue: CGFloat = 1.0

    public var centerView: UIView? {
        didSet {
            if let centerView = centerView {
                centerViewOffsetY = 0.0
                
                addSubview(centerView)
            }
        }
    }

    @IBInspectable
    public var tickColor: UIColor = UIColor.whiteColor() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var sectionsCount: Int = 0 {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBInspectable
    public var minValue: CGFloat = 0.0 {
        didSet {
            updateSectionsCount()
        }
    }
    
    @IBInspectable
    public var maxValue: CGFloat = 0.0 {
        didSet {
            updateSectionsCount()
        }
    }
    
    private func updateSectionsCount() {
        guard minValue < maxValue else {
            return
        }
        
        let items = maxValue - minValue + 1.0
        
        if items > 1 {
            sectionsCount = Int(items) + 2
        } else {
            sectionsCount = 0
        }
    }
    
    @IBInspectable
    public var numberOfTicksBetweenValues: UInt = 2 {
        didSet {
            tickValue = 1.0 / CGFloat(numberOfTicksBetweenValues + 1)
            
            updateSectionsCount()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        userInteractionEnabled = true
        
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0

        collectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.allowsSelection = false
        collectionView.delaysContentTouches = true

        collectionView.registerClass(SlidePickerCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(collectionView)
    }
   
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.frame = bounds
        
        centerView?.center = CGPointMake(frame.size.width / 2,
                                         centerViewOffsetY + (frame.size.height / 2) - 2)
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        layoutSubviews()
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        guard sectionsCount > 2 else {
            return CGSizeZero
        }
        
        if (indexPath.section == 0) || (indexPath.section == (sectionsCount - 1)) {
            return CGSizeMake((bounds.width / 2) - (spaceBetweenTicks / 2), bounds.height)
        }
        
        return CGSizeMake(spaceBetweenTicks, bounds.height)
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard sectionsCount > 2 else {
            return 0
        }
        
        if (section == 0) || (section >= (sectionsCount - 2)) {
            return 1
        } else {
            return Int(numberOfTicksBetweenValues) + 1
        }
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! SlidePickerCell
        
        cell.indexPath = indexPath
        cell.tickColor = tickColor
        cell.showTickLabels = showTickLabels
        cell.highlightTick = false

        if indexPath.section == 0 {
            cell.updateValue(CGFloat.min, type: .Empty)
        } else if indexPath.section == sectionsCount - 1 {
            cell.updateValue(CGFloat.max, type: .Empty)
        } else {
            let currentValue = minValue + CGFloat(indexPath.section - 1)

            if indexPath.row == 0 {
                if highlightCenterTick {
                    cell.highlightTick = (currentValue == ((maxValue - minValue) * 0.5 + minValue))
                } else {
                    cell.highlightTick = false
                }
                
                cell.updateValue(currentValue, type: .BigStroke)
            } else {
                cell.updateValue(currentValue + tickValue * CGFloat(indexPath.row), type: .SmallStroke)
            }
        }
        
        return cell
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return sectionsCount
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateSelectedValue()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateSelectedValue()
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if !snapEnabled {
            updateSelectedValue()
        }
    }
    
    public func scrollToValue(value: CGFloat, animated: Bool) {
        var indexPath: NSIndexPath?
        
        guard sectionsCount > 0 else {
            return
        }
        
        for i in 1 ... sectionsCount - 1 {
            indexPath = NSIndexPath(forRow: 0, inSection: i)
            
            let cell = collectionView(collectionView, cellForItemAtIndexPath: indexPath!) as? SlidePickerCell
            
            if let cell = cell where cell.value == value {
                delegate?.didSelectValue(cell.value)
                collectionView.scrollToItemAtIndexPath(indexPath!, atScrollPosition: .CenteredHorizontally, animated: animated)
                
                break
            }
        }
    }
    
    public func increaseValue() {
        let point = CGPointMake(collectionView.center.x + collectionView.contentOffset.x + spaceBetweenTicks * 2 / 3,
                                collectionView.center.y + collectionView.contentOffset.y)
        
        scrollToNearestCellAtPoint(point)
    }
    
    public func decreaseValue() {
        let point = CGPointMake(collectionView.center.x + collectionView.contentOffset.x - spaceBetweenTicks * 2 / 3,
            collectionView.center.y + collectionView.contentOffset.y)
        
        scrollToNearestCellAtPoint(point)
    }
    
    private func updateSelectedValue() {
        if snapEnabled {
            let initialPinchPoint = CGPointMake(collectionView.center.x + collectionView.contentOffset.x,
                                                collectionView.center.y + collectionView.contentOffset.y)

            scrollToNearestCellAtPoint(initialPinchPoint)
        } else {
            let percent = collectionView.contentOffset.x / (collectionView.contentSize.width - bounds.width)
            let absoluteValue = percent * (maxValue - minValue)
            let currentValue = max(min(absoluteValue + minValue, maxValue), minValue)
            
            delegate?.didSelectValue(currentValue)
        }
    }
    
    private func scrollToNearestCellAtPoint(point: CGPoint) {
        var centerCell: SlidePickerCell?
        
        let indexPath = collectionView.indexPathForItemAtPoint(point)
        
        if let iPath = indexPath {
            if (iPath.section == 0) || (iPath.section == (sectionsCount - 1)) {
                return
            }
            
            centerCell = self.collectionView(collectionView, cellForItemAtIndexPath: iPath) as? SlidePickerCell
        }
        
        guard let cell = centerCell else {
            return
        }
        
        delegate?.didSelectValue(cell.value)
        collectionView.scrollToItemAtIndexPath(indexPath!, atScrollPosition: .CenteredHorizontally, animated: true)
    }
}

public enum SlidePickerCellType {
    case Empty
    case BigStroke
    case SmallStroke
}

public class SlidePickerCell: UICollectionViewCell {
    
    public var showTickLabels = true {
        didSet {
            bigStrokePaddind = showTickLabels ?   4.0 : 2.5
            smallStrokePaddind = showTickLabels ? 8.0 : 6.0
        }
    }
    
    public var highlightTick = false

    private var type = SlidePickerCellType.Empty {
        didSet {
            
        }
    }
    
    public var value: CGFloat = 0.0 {
        didSet {
            let strValue = String(format: "%0.0f", self.value)
            
            valueLabel.text = "\(strValue)"
        }
    }
    
    public var indexPath: NSIndexPath?
    
    private let strokeView = UIView()
    private let valueLabel = UILabel()
    private let strokeWidth: CGFloat = 1.5
    private var bigStrokePaddind: CGFloat = 4.0
    private var smallStrokePaddind: CGFloat = 8.0
    
    public var tickColor = UIColor.whiteColor() {
        didSet {
            strokeView.backgroundColor = tickColor
            valueLabel.textColor = tickColor
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        strokeView.alpha = 0.0
        valueLabel.alpha = 0.0
        
        indexPath = nil
    }
    
    public func updateValue(value: CGFloat, type: SlidePickerCellType) {
        self.value = value
        self.type = type
        
        layoutSubviews()
    }
    
    private func commonInit() {
        strokeView.backgroundColor = UIColor.whiteColor()
        strokeView.alpha = 0.0
        strokeView.layer.masksToBounds = true
        strokeView.layer.cornerRadius = strokeWidth / 2
        
        valueLabel.textAlignment = .Center
        valueLabel.font = UIFont.systemFontOfSize(12.0)
        valueLabel.textColor = UIColor.whiteColor()
        valueLabel.alpha = 0.0

        contentView.addSubview(strokeView)
        contentView.addSubview(valueLabel)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = frame.size.height
        
        switch type {
            case .Empty:
                strokeView.alpha = 0.0
                valueLabel.alpha = 0.0
                break
                
            case .BigStroke:
                let widthAddition: CGFloat = highlightTick ? 0.5 : 0.0

                strokeView.alpha = 1.0
                valueLabel.alpha = showTickLabels ? 1.0 : 0.0
                
                if showTickLabels {
                    valueLabel.frame = CGRectMake(-5, 0, frame.size.width + 10, height / 3)
                    
                    strokeView.frame = CGRectMake((frame.size.width / 2) - (strokeWidth / 2) - widthAddition,
                                                  (height / 3) + bigStrokePaddind, strokeWidth + widthAddition * 2,
                                                  (height / 2) - (bigStrokePaddind * 2))
                    
                } else {
                    valueLabel.frame = CGRectZero
                    
                    strokeView.frame = CGRectMake((frame.size.width / 2) - (strokeWidth / 2) - widthAddition,
                                                  (height / 8) + bigStrokePaddind, strokeWidth + widthAddition * 2,
                                                  (height / 2) - (bigStrokePaddind * 2))
                }
                
                break

            case .SmallStroke:
                strokeView.alpha = 1.0
                valueLabel.alpha = 0.0
                
                valueLabel.frame = CGRectZero

                if showTickLabels {
                    strokeView.frame = CGRectMake((frame.size.width / 2) - (strokeWidth / 2),
                                                  (height / 3) + smallStrokePaddind, strokeWidth,
                                                  (height / 2) - (smallStrokePaddind * 2))
                    
                    valueLabel.frame = CGRectMake(0, 0, frame.size.width, height / 2)
                } else {
                    strokeView.frame = CGRectMake((frame.size.width / 2) - (strokeWidth / 2),
                                                  (height / 8) + smallStrokePaddind, strokeWidth,
                                                  (height / 2) - (smallStrokePaddind * 2))
                }
                break
        }
    }
}

internal extension UIImage {
    internal func tintImage(color: UIColor) -> UIImage {
        let scale: CGFloat = 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let context = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(context, 0, size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        let rect = CGRectMake(0, 0, size.width, size.height)
        
        CGContextSetBlendMode(context, .Normal)
        CGContextDrawImage(context, rect, CGImage)
        
        CGContextSetBlendMode(context, .SourceIn)
        color.setFill()
        CGContextFillRect(context, rect)
        
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return coloredImage.imageWithRenderingMode(.AlwaysOriginal)
    }
}
