{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{decode} = require('pgp-utils').armor

#================================================================================

exports.CoinbaseScraper = class CoinbaseScraper extends BaseScraper

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?) 
      new Error "Bad args to Coinbase proof: no username given"
    else if not (args.name?) or (args.name isnt 'coinbase')
      new Error "Bad args to Coinbase proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------

  profile_url : (username) -> "https://coinbase.com/#{username}/keybase"

  # ---------------------------------------------------------------------------

  hunt2 : ({username, proof_text_check, name}, cb) ->

    # calls back with rc, out
    rc       = v_codes.OK
    out      = {}

    unless (err = @_check_args { username, name })?
      url = @profile_url()
      out = 
        rc : rc
        api_url : url
        human_url : url
        remote_id : username
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) -> api_url is @profile_url(username)

  # ---------------------------------------------------------------------------

  check_status: ({username, api_url, proof_text_check, remote_id}, cb) ->

    # calls back with a v_code or null if it was ok
    await @_get_body api_url, defer err, rc, html

    if (rc is v_codes.OK)
      $ = @libs.cheerio.load html
      divs = $('div .keybase-proof')
      rc = if not divs.length then v_codes.FAILED_PARSE
      else if (divs.first()).indexOf(proof_text_check) >= 0 then v_codes.OK
      else  v_codes.NOT_FOUND

    cb err, rc
    
  # ---------------------------------------------------------------------------

  _get_body : (url, cb) ->
    @log "| HTTP request for URL '#{url}'"
    args =
      url : url
      headers : 
        "User-Agent" : constants.user_agent
      auth : @auth
    @_get_url_body args, cb

#================================================================================

