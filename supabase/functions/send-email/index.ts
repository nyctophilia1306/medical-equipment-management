import { createTransport } from "npm:nodemailer@6.9.7"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  type: string
  to: string
  data: Record<string, any>
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { type, to, data }: EmailRequest = await req.json()

    // Create nodemailer transport for Gmail
    const transporter = createTransport({
      service: 'gmail',
      auth: {
        user: Deno.env.get("SMTP_USERNAME")!,
        pass: Deno.env.get("SMTP_PASSWORD")!,
      },
    })

    let subject = ""
    let html = ""

    switch (type) {
      case "new_request":
        subject = `Yêu cầu mượn thiết bị mới từ ${data.user_name}`
        html = `
          <h2>Yêu cầu mượn thiết bị mới</h2>
          <p><strong>Người mượn:</strong> ${data.user_name}</p>
          <p><strong>Thiết bị:</strong> ${data.equipment_name}</p>
          <p><strong>Mã yêu cầu:</strong> ${data.request_id}</p>
          <p>Vui lòng đăng nhập vào hệ thống để xem chi tiết và duyệt yêu cầu.</p>
        `
        break

      case "request_approved":
        subject = `Yêu cầu mượn thiết bị được duyệt`
        html = `
          <h2>Yêu cầu của bạn đã được duyệt</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Yêu cầu mượn thiết bị <strong>${data.equipment_name}</strong> của bạn đã được chấp thuận.</p>
          <p><strong>Ngày mượn:</strong> ${new Date(data.borrow_date).toLocaleDateString('vi-VN')}</p>
          <p><strong>Ngày trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p>Vui lòng đến nhận thiết bị theo đúng thời gian.</p>
        `
        break

      case "request_rejected":
        subject = `Yêu cầu mượn thiết bị bị từ chối`
        html = `
          <h2>Yêu cầu của bạn bị từ chối</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Yêu cầu mượn thiết bị <strong>${data.equipment_name}</strong> của bạn đã bị từ chối.</p>
          <p><strong>Lý do:</strong> ${data.reason}</p>
          <p>Vui lòng liên hệ với quản trị viên để biết thêm chi tiết.</p>
        `
        break

      case "equipment_overdue":
        subject = `Thiết bị quá hạn trả - Vui lòng trả ngay`
        html = `
          <h2>Thiết bị đã quá hạn trả</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Thiết bị <strong>${data.equipment_name}</strong> của bạn đã quá hạn trả ${data.days_overdue} ngày.</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p style="color: red;"><strong>Vui lòng trả thiết bị ngay lập tức để tránh bị xử lý kỷ luật.</strong></p>
        `
        break

      case "equipment_overdue_admin":
        subject = `Thiết bị quá hạn - ${data.user_name}`
        html = `
          <h2>Cảnh báo thiết bị quá hạn</h2>
          <p><strong>Người mượn:</strong> ${data.user_name}</p>
          <p><strong>Thiết bị:</strong> ${data.equipment_name}</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p><strong>Số ngày quá hạn:</strong> ${data.days_overdue} ngày</p>
          <p>Vui lòng liên hệ với người mượn để thu hồi thiết bị.</p>
        `
        break

      case "return_reminder":
        subject = `Nhắc nhở: Sắp đến hạn trả thiết bị`
        html = `
          <h2>Nhắc nhở trả thiết bị</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Thiết bị <strong>${data.equipment_name}</strong> của bạn sắp đến hạn trả.</p>
          <p><strong>Ngày hẹn trả:</strong> ${new Date(data.return_date).toLocaleDateString('vi-VN')}</p>
          <p>Vui lòng chuẩn bị trả thiết bị đúng hạn.</p>
        `
        break

      case "welcome":
        subject = `Chào mừng đến với Hệ thống Quản lý Thiết bị Y tế`
        html = `
          <h2>Chào mừng ${data.user_name}!</h2>
          <p>Cảm ơn bạn đã đăng ký tài khoản tại Hệ thống Quản lý Thiết bị Y tế.</p>
          <p>Bạn có thể đăng nhập và bắt đầu sử dụng hệ thống ngay bây giờ.</p>
          <p>Nếu bạn có bất kỳ thắc mắc nào, vui lòng liên hệ với quản trị viên.</p>
        `
        break

      case "password_reset":
        subject = `Mật khẩu của bạn đã được đặt lại`
        html = `
          <h2>Mật khẩu đã được đặt lại</h2>
          <p>Xin chào ${data.user_name},</p>
          <p>Mật khẩu của bạn đã được đặt lại thành công.</p>
          <p>Vui lòng đăng nhập và đổi mật khẩu mới để bảo mật tài khoản.</p>
        `
        break

      default:
        throw new Error(`Unknown email type: ${type}`)
    }

    // Send email using nodemailer
    const info = await transporter.sendMail({
      from: Deno.env.get("SMTP_FROM_EMAIL")!,
      to: to,
      subject: subject,
      html: html,
    })

    return new Response(
      JSON.stringify({ success: true, messageId: info.messageId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error("Email function error:", error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        stack: error.stack,
        details: String(error)
      }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
