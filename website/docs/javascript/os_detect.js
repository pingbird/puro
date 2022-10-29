let me = document.currentScript
let tabbedSet = me.previousElementSibling
let tabs = tabbedSet.querySelectorAll("input")

// https://stackoverflow.com/a/38241481/2615007
function getOS() {
    let userAgent = window.navigator.userAgent,
        platform = window.navigator?.userAgentData?.platform || window.navigator.platform,
        macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'],
        windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'],
        iosPlatforms = ['iPhone', 'iPad', 'iPod'],
        os = null;

    if (macosPlatforms.indexOf(platform) !== -1) {
        return 'Mac';
    } else if (iosPlatforms.indexOf(platform) !== -1) {
        return 'iOS';
    } else if (windowsPlatforms.indexOf(platform) !== -1) {
        return 'Windows';
    } else if (/Android/.test(userAgent)) {
        return 'Android';
    } else if (/Linux/.test(platform)) {
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