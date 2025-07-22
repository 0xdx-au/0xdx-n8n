# 🔐 N8N Google Docs Integration Setup Complete

## ✅ Google Cloud SDK Status

- **Google Cloud SDK**: ✅ Installed and authenticated
- **Project ID**: `n8n-doc-secure`
- **Service Account**: `n8n-document-automation@n8n-doc-secure.iam.gserviceaccount.com`
- **Key File**: `W:\DEV\.gcp-credentials\n8n-document-service-account.json`
- **APIs Enabled**: Google Docs API, Google Drive API, IAM API

## 🛡️ Security Configuration

### Service Account Permissions (Minimal)
- **Google Docs API**: Enabled for document creation/editing
- **Google Drive API**: File-level access only (can only access files it creates)
- **IAM API**: For service account management

### File Security
- Service account key file restricted to current user only
- No public access or anonymous authentication
- Time-limited access tokens automatically managed

## 📋 N8N Integration Steps

### 1. Add Google API Credentials in N8N

1. Access your N8N instance: https://localhost/n8n/
2. Go to **Settings** → **Credentials**
3. Click **Create New Credential**
4. Select **Google API** (or **Google Service Account**)

### 2. Configure Authentication

**Authentication Method**: Service Account
- **Service Account Email**: `n8n-document-automation@n8n-doc-secure.iam.gserviceaccount.com`
- **Private Key File**: Upload `W:\DEV\.gcp-credentials\n8n-document-service-account.json`

**Required Scopes**:
```
https://www.googleapis.com/auth/documents
https://www.googleapis.com/auth/drive.file
```

### 3. Workflow Configuration

Use the provided workflow template: `n8n-document-workflow-template.json`

**Key Security Features**:
- Input validation and sanitization
- Whitelist-based document type validation
- XSS and script injection protection
- Secure token-based download URLs
- Comprehensive audit logging
- No public document access

## 🔧 API Usage Examples

### Create Document from Template
```bash
curl -X POST https://localhost/webhook/create-document \
  -H "Content-Type: application/json" \
  -d '{
    "documentType": "contract",
    "templateId": "YOUR_TEMPLATE_DOCUMENT_ID",
    "replacements": {
      "CLIENT_NAME": "John Doe",
      "CONTRACT_DATE": "2025-07-22",
      "AMOUNT": "$1,000"
    }
  }'
```

### Expected Response
```json
{
  "success": true,
  "documentId": "NEW_DOCUMENT_ID",
  "requestId": "doc-1721652000000-abc123def",
  "downloadUrl": "https://your-secure-domain.com/api/download/doc-1721652000000-abc123def?token=SECURE_TOKEN",
  "expiresAt": "2025-07-23T14:58:00.000Z",
  "message": "Document created successfully. Download link expires in 24 hours.",
  "security": {
    "tokenBased": true,
    "timeExpired": true,
    "noPublicAccess": true
  }
}
```

## 📁 Template Setup

### 1. Create Document Templates

1. Create Google Docs with placeholder text:
   - `{{CLIENT_NAME}}` - Will be replaced with form data
   - `{{CONTRACT_DATE}}` - Will be replaced with current date
   - `{{AMOUNT}}` - Will be replaced with form data
   - `{{DOCUMENT_TYPE}}` - Automatically set based on request
   - `{{REQUEST_ID}}` - Unique request identifier

### 2. Get Template IDs

1. Open your template document in Google Docs
2. Copy the document ID from the URL:
   `https://docs.google.com/document/d/DOCUMENT_ID/edit`
3. Use this ID in your N8N workflow

### 3. Secure Folder Structure

1. Create a "Templates" folder in Google Drive
2. Create a "Generated Documents" folder 
3. Set appropriate sharing permissions (private only)
4. Use folder IDs in your N8N workflow configuration

## 🔒 OPSEC Considerations

### Access Control
- Service account has minimal required permissions only
- No OAuth user authentication (service-to-service only)
- All generated documents are private by default
- Download links expire after 24 hours

### Monitoring
- All document creation events are logged
- Security audit trail maintained
- No sensitive data exposed in logs
- Rate limiting should be implemented at nginx level

### Key Rotation
- Rotate service account keys every 90 days
- Monitor service account usage in Google Cloud Console
- Revoke unused keys immediately

## 🚨 Security Best Practices

1. **Never commit service account keys to git**
2. **Regularly monitor API usage quotas**
3. **Implement rate limiting on webhooks**
4. **Validate all user inputs**
5. **Use HTTPS only for all communications**
6. **Implement proper error handling (no sensitive data in errors)**
7. **Set up alerting for unusual API activity**

## 📊 Monitoring & Logging

### N8N Workflow Logs
- Document creation requests
- Validation failures
- API call results
- Download link generation

### Google Cloud Audit Logs
- Service account authentication events
- API calls and responses
- Permission changes
- Key usage

## 🧪 Testing Your Setup

### 1. Test API Authentication
```bash
gcloud auth application-default print-access-token
```

### 2. Test N8N Webhook
```bash
curl -X POST https://localhost/webhook/create-document \
  -H "Content-Type: application/json" \
  -d '{"documentType": "test", "templateId": "TEST_ID", "replacements": {"TEST": "value"}}'
```

### 3. Verify Security Headers
```bash
curl -I https://localhost/webhook/create-document
```

## 📞 Support

For issues with this integration:
1. Check N8N workflow execution logs
2. Verify Google Cloud service account permissions
3. Check API quota limits in Google Cloud Console
4. Review audit logs for authentication issues

---

**Project**: 0xdx-n8n Secure Document Automation
**Security Level**: Production-ready with maximum OPSEC
**Last Updated**: 2025-07-22
**Dedicated to**: CH41B01
