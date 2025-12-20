public let stableDwmacAppId: String = "hillyu.dwmac"
#if DEBUG
    public let dwmacAppId: String = "hillyu.dwmac.debug"
    public let dwmacAppName: String = "Dwmac-Debug"
#else
    public let dwmacAppId: String = stableDwmacAppId
    public let dwmacAppName: String = "Dwmac"
#endif
