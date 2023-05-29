-- 语言枚举
gLanguage = {
    arab = 0, -- 阿拉伯语
    en = 1, -- 英语
    de = 2, -- 德语
    es = 3, -- 西班牙语
    fr = 4, -- 法语
    ru = 5, -- 俄語
    it = 6, -- 意大利语
    pt = 7, -- 葡萄牙语
    fa = 8, -- 波斯语
    tr = 9, -- 土耳其语
    ko = 10, -- 朝鲜语
    ja = 11, -- 日语
    th = 12, -- 泰语
    id = 13, -- 印尼
    pl = 14, -- 波兰语
    ro = 15, -- 罗马尼亚
    nl = 16, -- 荷兰
    vi = 17, -- 越南
    sv = 18, -- 瑞典
    zh_cn = 19, -- 简体中文
    zh_tw = 20 -- 繁体中文
}

gLanguageChange = {
    ["zh-CN"] = "zh_cn",
    ["zh-TW"] = "zh_tw"
}

gLanguageAbbrToStandard = {
    ["zh_cn"] = "zh-CN",
    ["zh_tw"] = "zh-TW"
}

setmetatable(
    gLanguageAbbrToStandard,
    {
        __index = function(t, k)
            return k
        end
    }
)

-- 语言枚举对应简称
gLanguageAbbr = {
    [gLanguage.arab] = "ar", -- 阿拉伯语
    [gLanguage.en] = "en", -- 英语
    [gLanguage.de] = "de", -- 德语
    [gLanguage.es] = "es", -- 西班牙语
    [gLanguage.fr] = "fr", -- 法语
    [gLanguage.ru] = "ru", -- 俄語
    [gLanguage.it] = "it", -- 意大利语
    [gLanguage.pt] = "pt", -- 葡萄牙语
    [gLanguage.fa] = "fa", -- 波斯语
    [gLanguage.tr] = "tr", -- 土耳其语
    [gLanguage.ko] = "ko", -- 朝鲜语
    [gLanguage.ja] = "ja", -- 日语
    [gLanguage.th] = "th", -- 泰语
    [gLanguage.id] = "id", -- 印尼
    [gLanguage.pl] = "pl", -- 波兰语
    [gLanguage.ro] = "ro", -- 罗马尼亚
    [gLanguage.nl] = "nl", -- 荷兰
    [gLanguage.vi] = "vi", -- 越南
    [gLanguage.sv] = "sv", -- 瑞典
    [gLanguage.zh_cn] = "zh_cn", -- 中文
    [gLanguage.zh_tw] = "zh_tw" -- 繁体中文
}
