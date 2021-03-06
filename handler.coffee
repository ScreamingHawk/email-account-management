AWS = require 'aws-sdk'
uuidv4 = require 'uuid/v4'
querystring = require 'querystring'

config = require "config.#{process.env.stage}.json"

s3 = new AWS.S3()
ses = new AWS.SES
	region: config.awsSesRegion

# Get the email data from S3
getS3 = (email, state, callback) =>
	params =
		Bucket: config.bucketName
		Key: "#{state}/#{email}"
	s3.getObject params, callback

# Put the email data in S3
putS3 = (email, state, data, callback) =>
	params =
		Bucket: config.bucketName
		Key: "#{state}/#{email}"
		Body: data
	s3.putObject params, callback

# Delete the email data from S3
deleteS3 = (email, state, callback) =>
	params =
		Bucket: config.bucketName
		Key: "#{state}/#{email}"
	s3.deleteObject params, callback

# Sends an email
sendEmail = (email, subject, textContent, htmlContent, callback) =>
	params =
		Destination:
			ToAddresses: [
				email
			]
		Message:
			Subject:
				Data: subject
			Body:
				Html:
					Data: htmlContent
				Text:
					Data: textContent
		Source: config.sourceEmail
		ReplyToAddresses: [
			config.replyToEmail ? config.sourceEmail
		]
	ses.sendEmail params, callback

# Respond with the given information
respondWith = (code, body, errMessage, callback, redirectLocation=null) =>
	if errMessage? && !body?
		body =
			message: errMessage
	response =
		statusCode: code
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify body
	if redirectLocation?
		response.headers.Location = redirectLocation
	callback errMessage, response

# Request the email address be added
module.exports.addEmail = (event, context, lambdaCallback) =>
	email = event?.email
	if !email? && event?.body?
		# Try the body
		email = querystring.parse event.body
			?.email
	if !email?
		console.log event
		return respondWith 400, null, "Email not supplied", lambdaCallback
	# Check completed only, if pending ignore and reset the request
	getS3 email, "completed", (err) ->
		if !err?
			# We want an error here
			return respondWith 409, null, "This email already exists", lambdaCallback
		if err.statusCode != 404
			# Error should be 404
			console.log err
			return respondWith 500, null, "Something unexpected went wrong when checking email", lambdaCallback
		# Good. Store it
		token = uuidv4()
		putS3 email, "pending", token, (err)->
			if err?
				console.log err
				return respondWith 500, null, "Something unexpected went wrong when adding email", lambdaCallback
			url = "#{config.serviceEndpoint}/accounts/#{email}/confirm?token=#{token}"
			bodyText = config.confirmEmailTemplate.bodyText.replace /{{confirmUrl}}/g, url
			bodyHtml = config.confirmEmailTemplate.bodyHtml.replace /{{confirmUrl}}/g, url
			sendEmail email, config.confirmEmailTemplate.subject, bodyText, bodyHtml, (err)->
				if err?
					console.log err
					return respondWith 500, null, "Something unexpected went wrong when sending email", lambdaCallback
				console.log "Confirmation token for #{email} is #{token}"
				return respondWith 200, "Please check your email", null, lambdaCallback

# Confirm the email address is valid
module.exports.confirmEmail = (event, context, lambdaCallback) =>
	email = event?.email ? event?.pathParameters?.email
	if !email?
		console.log event
		return respondWith 400, null, "Email not supplied", lambdaCallback
	token = event?.token ? event?.queryStringParameters?.token
	if !token?
		console.log event
		return respondWith 400, null, "Confirmation token not supplied", lambdaCallback
	getS3 email, "pending", (err, content) ->
		if err?.statusCode == 404
			return respondWith 404, null, "Email confirmation not pending", lambdaCallback

		if token != String content.Body
			console.log "Token provided (#{token}) doesn't match token stored (#{content.Body})"
			return respondWith 302, "Email confirmation failed", "Token does not match", lambdaCallback, redirectLocation=config.confirmFailRedirect

		# Good. Store it completed
		token = uuidv4()
		putS3 email, "completed", token, (err)->
			if err?
				console.log err
				return respondWith 500, null, "Something unexpected went wrong when confirming email", lambdaCallback
			deleteS3 email, "pending", (err)->
				if err?
					console.log err
					return respondWith 500, null, "Something unexpected went wrong when removing email from pending", lambdaCallback
				console.log "Removal token for #{email} is #{token}"
				return respondWith 302, "Email confirmed", null, lambdaCallback, redirectLocation=config.confirmSuccessRedirect

# Request email removal
module.exports.removeEmail = (event, context, lambdaCallback) =>
	email = event?.email ? event?.pathParameters?.email
	if !email?
		console.log event
		return respondWith 400, null, "Email not supplied", lambdaCallback
	if config.removeRequiresToken && !event?.token?
		console.log event
		return respondWith 400, null, "Confirmation token not supplied", lambdaCallback

	removeIt = (email, lambdaCallback) ->
		deleteS3 email, "completed", (err)->
			if err?.statusCode == 204
				console.log err
				return respondWith 404, "Email removal failed", "Email not found", lambdaCallback, redirectLocation=config.removeFailRedirect
			if err?
				console.log err
				return respondWith 500, null, "Something unexpected went wrong when removing email", lambdaCallback
			return respondWith 302, "Email removed", null, lambdaCallback, redirectLocation=config.removeSuccessRedirect

	if config.removeRequiresToken
		# Check the token
		token = event?.token ? event?.queryStringParameters?.token
		getS3 email, "completed", (err, content) ->
			if err?.statusCode == 404
				return respondWith 404, null, "Email confirmation not completed", lambdaCallback

			if token != String content.Body
				console.log "Token provided (#{token}) doesn't match token stored (#{content.Body})"
				return respondWith 302, "Email removal failed", "Token does not match", lambdaCallback, redirectLocation=config.removeFailRedirect
			removeIt email, lambdaCallback
	else
		removeIt email, lambdaCallback
