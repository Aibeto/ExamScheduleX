// ...复制 notification/scripts/reminderQueue.js 的全部内容...
var reminderQueue = (function() {
    var queue = [];
    var audioCache = {};
    var currentAudio = null; // 当前正在播放的音频对象
    var isStopped = false;   // 标记是否已停止提醒

    function addReminder(reminder) {
        queue.push(reminder);
        queue.sort(function(a, b) {
            return a.time - b.time;
        });
        preloadAudio(reminder.audio);
    }

    function processQueue() {
        if (isStopped) {
            setTimeout(processQueue, 1000);
            return;
        }
        var now = Date.now();
        while (queue.length > 0 && queue[0].time <= now) {
            var reminder = queue.shift();
            executeReminder(reminder);
        }
        setTimeout(processQueue, 1000);
    }

    function executeReminder(reminder) {
        stop(); // 确保不会有多个音频同时播放
        var audioObj = null;
        if (audioCache[reminder.audio]) {
            audioObj = audioCache[reminder.audio];
        } else if (audioController.getAudioSrc(reminder.audio)) {
            audioObj = new Audio(audioController.getAudioSrc(reminder.audio));
            audioCache[reminder.audio] = audioObj;
        }
        if (audioObj) {
            currentAudio = audioObj;
            currentAudio.currentTime = 0;
            currentAudio.play();
        } else {
            errorSystem.show('音频文件不存在: ' + reminder.audio, 'error');
        }
    }

    function preloadAudio(audioType) {
        if (!audioCache[audioType] && audioController.getAudioSrc(audioType)) {
            var audio = new Audio(audioController.getAudioSrc(audioType));
            audioCache[audioType] = audio;
        }
    }

    function stop() {
        isStopped = true;
        if (currentAudio) {
            try {
                currentAudio.pause();
                currentAudio.currentTime = 0;
            } catch (e) {}
            currentAudio = null;
        }
        // 1秒后允许继续处理队列（防止误触）
        setTimeout(function() {
            isStopped = false;
        }, 1000);
    }

    return {
        addReminder: addReminder,
        processQueue: processQueue,
        stop: stop
    };
})();

reminderQueue.processQueue();
