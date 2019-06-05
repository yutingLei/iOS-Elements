/*****************************************************
 
 ELImagePreview
 图片预览
 
 
 
 
 *****************************************************/
import UIKit

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

public extension ELImagePreview {
    
    /// 展示风格
    enum Style {
        case light
        case dark
    }
    
    /// 页面指示格式
    enum PageIndexFormat {
        case none
        case dot                /// 用圆点表示
        case short              /// 1/10
        case medium             /// 第1/10页
        case long               /// 第1页,共10页
        case custom(String)     /// 例如'自定义第%@页，自定义共%@页',最多包含两个'%@'
    }
}

public class ELImagePreview: UIView {
    
    /// 容器
    private var _container: UIScrollView!
    
    /// 图片集
    private(set) public var images: [UIImage]!
    
    /// 最大放大倍数(3)
    public var maxZoomScale: CGFloat = 3
    
    /// 初始化实例
    ///
    public init(_ images: [UIImage]) {
        super.init(frame: UIScreen.main.bounds)
        self.alpha = 0
        self.backgroundColor = .white
        
        self.images = images
        createContainerView(with: images.count)
        createImagePreviewCells(with: images)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: Creating
private extension ELImagePreview {
    
    /// 初始化容器
    func createContainerView(with count: Int) {
        _container = UIScrollView(frame: bounds)
        _container.contentSize = CGSize(width: CGFloat(count) * screenWidth, height: 0)
        _container.showsHorizontalScrollIndicator = false
        _container.showsVerticalScrollIndicator = false
        _container.backgroundColor = .white
        _container.isPagingEnabled = true
        _container.delegate = self
        addSubview(_container)
        
        /// Hidden view when tapped
        let tap = UITapGestureRecognizer(target: self, action: #selector(hide))
        tap.cancelsTouchesInView = false
        _container.addGestureRecognizer(tap)
    }
    
    /// 创建子视图
    func createImagePreviewCells(with contents: [Any]) {
        var rect = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        for content in contents {
            let cell = ELImagePreviewCell(frame: rect, with: content)
            cell.maximumZoomScale = maxZoomScale
            _container.addSubview(cell)
            rect.origin.x += screenWidth
        }
    }
}

extension ELImagePreview: UIScrollViewDelegate {
    
    /// Did drag ended
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / screenWidth)
        for i in 0..<_container.subviews.count {
            if i != index {
                (_container.subviews[i] as? ELImagePreviewCell)?.zoomScale = 1
            }
        }
    }
}

//MARK: Display & Hide
public extension ELImagePreview {
    
    /// 显示
    func makeVisiable(from rect: CGRect? = nil) {
        if superview == nil {
            UIApplication.shared.keyWindow?.addSubview(self)
            UIView.animate(withDuration: 0.35) {[weak self] in
                self?.alpha = 1
            }
        }
    }
    
    /// 隐藏
    @objc func hide() {
        UIView.animate(withDuration: 0.35, animations: {[weak self] in
            self?.alpha = 0
        }) {[weak self] _ in
            self?.removeFromSuperview()
        }
    }
}

//MARK: -  图片Cell
fileprivate class ELImagePreviewCell: UIScrollView, UIScrollViewDelegate {
    
    /// 图片视图
    var imageView: UIImageView?
    
    /// 初始化实例
    ///
    /// - Parameters:
    ///   - frame: Cell大小及位置
    ///   - content: 图片或图片地址
    init(frame: CGRect, with content: Any) {
        super.init(frame: frame)
        delegate = self
        backgroundColor = .white
        
        imageView = UIImageView(frame: bounds)
        imageView?.contentMode = .scaleAspectFit
        addSubview(imageView!)
        
        /// Image
        if let image = content as? UIImage {
            imageView?.image = image
        }
        
        /// A path
        if let path = content as? String, let url = URL(string: path) {
            let queue = DispatchQueue(label: "kELLoadImageQueue")
            queue.async {[weak self] in
                do {
                    let imageData = try Data(contentsOf: url)
                    self?.imageView?.image = UIImage(data: imageData)
                } catch {
                    print("Load Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Zooming view
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
