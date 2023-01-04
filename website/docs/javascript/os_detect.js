let me = document.currentScript
let tabbedSet = me.previousElementSibling
let tabs = tabbedSet.querySelectorAll("input")

// https://stackoverflow.com/a/38241481/2615007
function getOS() {
    let userAgent = window.navigator.userAgent,
        platform = (window.navigator?.userAgentData?.platform || window.navigator.platform).toLowerCase(),
        macosPlatforms = ['macintosh', 'macintel', 'macppc', 'mac68k', 'macos'],
        windowsPlatforms = ['win32', 'win64', 'windows', 'wince'],
        iosPlatforms = ['iphone', 'ipad', 'ipod'],
        os = null;

    if (macosPlatforms.indexOf(platform) !== -1) {
        return 'Mac';
    } else if (iosPlatforms.indexOf(platform) !== -1) {
        return 'iOS';
    } else if (windowsPlatforms.indexOf(platform) !== -1) {
        return 'Windows';
    } else if (/android/.test(userAgent)) {
        return 'Android';
    } else if (/linux/.test(platform)) {
        return 'Linux';
    }
}

switch (getOS()) {
    case 'Linux':
        tabs[1].click()
        break;
    case 'Mac':
        tabs[2].click()
        break;
}