import UIKit

extension JetpackExtensions where Base: UIView {
    
	public var alpha: Receiver<CGFloat> {
        return jx_makeReceiver(key: #function) { $0.alpha = $1 }
	}

	public var isHidden: Receiver<Bool> {
		return jx_makeReceiver(key: #function) { $0.isHidden = $1 }
	}

	public var isUserInteractionEnabled: Receiver<Bool> {
		return jx_makeReceiver(key: #function) { $0.isUserInteractionEnabled = $1 }
	}
}
