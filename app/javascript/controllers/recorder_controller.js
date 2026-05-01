import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["durationInput", "fileInput", "preview", "recordButton", "status", "submitButton", "timer"]
  static values = { maxSeconds: Number }

  connect() {
    this.mediaRecorder = null
    this.stream = null
    this.chunks = []
    this.elapsedSeconds = 0
    this.countdown = null
    this.updateTimer(this.maxSecondsValue || 180)
  }

  disconnect() {
    this.stopStream()
    this.clearCountdown()
  }

  async toggle() {
    if (this.mediaRecorder?.state === "recording") {
      this.stopRecording()
      return
    }

    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      this.statusTarget.textContent = "このブラウザでは録音 API が使えません。下のファイル選択から音声を追加してください。"
      return
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.chunks = []
      this.elapsedSeconds = 0
      this.mediaRecorder = new MediaRecorder(this.stream)

      this.mediaRecorder.addEventListener("dataavailable", (event) => {
        if (event.data.size > 0) this.chunks.push(event.data)
      })

      this.mediaRecorder.addEventListener("stop", () => this.persistRecording())

      this.mediaRecorder.start()
      this.recordButtonTarget.textContent = "Stop"
      this.recordButtonTarget.classList.remove("bg-slate-950")
      this.recordButtonTarget.classList.add("bg-rose-600")
      this.statusTarget.textContent = "録音中です。3 分で自動停止します。"
      this.submitButtonTarget.disabled = true
      this.startCountdown()
    } catch (_error) {
      this.statusTarget.textContent = "マイクにアクセスできませんでした。ブラウザの権限設定を確認してください。"
    }
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("hidden")
    this.submitButtonTarget.disabled = false
    this.statusTarget.textContent = "音声ファイルを準備しました。保存して続けられます。"
  }

  stopRecording() {
    this.clearCountdown()

    if (this.mediaRecorder?.state === "recording") {
      this.mediaRecorder.stop()
    }

    this.recordButtonTarget.textContent = "Rec"
    this.recordButtonTarget.classList.remove("bg-rose-600")
    this.recordButtonTarget.classList.add("bg-slate-950")
    this.stopStream()
  }

  startCountdown() {
    const maxSeconds = this.maxSecondsValue || 180
    this.updateTimer(maxSeconds)

    this.countdown = window.setInterval(() => {
      this.elapsedSeconds += 1
      const remaining = Math.max(maxSeconds - this.elapsedSeconds, 0)
      this.durationInputTarget.value = this.elapsedSeconds
      this.updateTimer(remaining)

      if (remaining === 0) {
        this.stopRecording()
      }
    }, 1000)
  }

  clearCountdown() {
    if (!this.countdown) return

    window.clearInterval(this.countdown)
    this.countdown = null
  }

  persistRecording() {
    const blob = new Blob(this.chunks, { type: this.mediaRecorder?.mimeType || "audio/webm" })
    const file = new File([blob], `furitsumu-${Date.now()}.webm`, { type: blob.type })
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.fileInputTarget.files = dataTransfer.files
    this.fileSelected()
  }

  stopStream() {
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
  }

  updateTimer(totalSeconds) {
    const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, "0")
    const seconds = (totalSeconds % 60).toString().padStart(2, "0")
    this.timerTarget.textContent = `${minutes}:${seconds}`
  }
}
