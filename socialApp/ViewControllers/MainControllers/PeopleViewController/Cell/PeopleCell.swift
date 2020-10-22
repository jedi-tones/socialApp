//
//  PeopleCell.swift
//  socialApp
//
//  Created by Денис Щиголев on 26.08.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import UIKit
import SDWebImage

class PeopleCell: UICollectionViewCell,PeopleConfigurationCell {

    static var reuseID = "PeopleCell"
    
    weak var likeDislikeDelegate: LikeDislikeTappedDelegate?
    var person: MPeople?
    let scrollView = UIScrollView()
    let galleryScrollView = GalleryScrollView(imagesURL: [])
    var infoLabel = UILabel(labelText: "0.00KM", textFont: .avenirRegular(size: 14),textColor: .myGrayColor())
    var distanceLabel = UILabel(labelText: "", textFont: .avenirRegular(size: 14),textColor: .myGrayColor())
    var advertLabel = UILabel(labelText: "",
                              textFont: .avenirRegular(size: 18),
                              textColor: .myGrayColor(),
                              aligment: .left,
                              linesCount: 5)
    let geoImage = UIImageView(systemName: "location.circle", config: .init(font: .avenirRegular(size: 14)), tint: .myGrayColor())
    let infoImage = UIImageView(systemName: "info.circle", config: .init(font: .avenirRegular(size: 14)), tint: .myGrayColor())
    let likeImage = UIImageView(systemName: "info.circle", config: .init(font: .avenirRegular(size: 14)), tint: .myGrayColor())
    let dislikeButton = UIButton(image: UIImage(systemName: "xmark",
                                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .large)) ?? #imageLiteral(resourceName: "reject"),
                                 tintColor: .myLabelColor(),
                                 backgroundColor: .myLightGrayColor())
    let likeButton = UIButton(image: UIImage(systemName: "suit.heart",
                                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .large)) ?? #imageLiteral(resourceName: "reject"),
                              tintColor: .myWhiteColor(),
                              backgroundColor: .myLabelColor())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        layer.cornerRadius = MDefaultLayer.bigCornerRadius.rawValue
        clipsToBounds = true
        
        scrollView.updateContentView()
        scrollView.showsVerticalScrollIndicator = false
        
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        dislikeButton.addTarget(self, action: #selector(dislikeTapped), for: .touchUpInside)
    }
    func configure(with value: MPeople, complition: @escaping()-> Void) {
        
        person = value
        galleryScrollView.setupImages(imagesURL: [value.userImage] + value.gallery) {
            complition()
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 0.8
        paragraph.alignment = .left
        
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle : paragraph
        ]
        
        advertLabel.attributedText = NSMutableAttributedString(string: value.advert, attributes: attributes)
        
        infoLabel.text = [value.dateOfBirth.getAge(), value.gender, value.sexuality].joined(separator: ", ").lowercased()
        distanceLabel.text = "\(value.distance) км от тебя"
        
    }
    
    override func prepareForReuse() {
        galleryScrollView.prepareReuseScrollView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.updateContentView()
        likeButton.layer.cornerRadius = likeButton.frame.width / 2
        dislikeButton.layer.cornerRadius = dislikeButton.frame.width / 2
    }
}

extension PeopleCell {
    @objc private func likeTapped() {
        if let person = person {
            likeDislikeDelegate?.likePeople(people: person)
        }
    }
    
    @objc private func dislikeTapped() {
        if let person = person {
            likeDislikeDelegate?.dislikePeople(people: person)
        }
    }
}
extension PeopleCell {
    private func setupConstraints() {
        
        addSubview(scrollView)
        scrollView.addSubview(galleryScrollView)
        scrollView.addSubview(infoLabel)
        scrollView.addSubview(distanceLabel)
        scrollView.addSubview(advertLabel)
        scrollView.addSubview(geoImage)
        scrollView.addSubview(infoImage)
        scrollView.addSubview(likeButton)
       scrollView.addSubview(dislikeButton)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        advertLabel.translatesAutoresizingMaskIntoConstraints = false
        geoImage.translatesAutoresizingMaskIntoConstraints = false
        infoImage.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        dislikeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            galleryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryScrollView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            galleryScrollView.heightAnchor.constraint(equalTo: galleryScrollView.widthAnchor, multiplier: 1.3),
            
            infoImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoImage.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: 20),
            
            infoLabel.leadingAnchor.constraint(equalTo: infoImage.trailingAnchor, constant: 7),
            infoLabel.topAnchor.constraint(equalTo: infoImage.topAnchor),
            
            geoImage.leadingAnchor.constraint(equalTo: infoImage.leadingAnchor),
            geoImage.topAnchor.constraint(equalTo: infoLabel.bottomAnchor),
            
            distanceLabel.leadingAnchor.constraint(equalTo: geoImage.trailingAnchor, constant: 7),
            distanceLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor),
            
            advertLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            advertLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            advertLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 20),
            
            likeButton.trailingAnchor.constraint(equalTo: galleryScrollView.trailingAnchor),
            likeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            likeButton.heightAnchor.constraint(equalTo: galleryScrollView.widthAnchor, multiplier: 0.15),
            likeButton.widthAnchor.constraint(equalTo: likeButton.heightAnchor),

            dislikeButton.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -20),
            dislikeButton.bottomAnchor.constraint(equalTo: likeButton.bottomAnchor),
            dislikeButton.heightAnchor.constraint(equalTo: galleryScrollView.widthAnchor, multiplier: 0.15),
            dislikeButton.widthAnchor.constraint(equalTo: dislikeButton.heightAnchor),
        ])
    }
}