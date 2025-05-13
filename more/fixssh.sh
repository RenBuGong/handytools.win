# 1. 如果有 GitLab Personal Access Token（PAT），查自己帐号下有哪些 key
curl --header "PRIVATE-TOKEN: <PAT>" https://gitlab.gbox.one/api/v4/user/keys

# 2. 再查 deploy-keys 是否启用
curl --header "PRIVATE-TOKEN: <PAT>" \
     "https://gitlab.gbox.one/api/v4/projects/<项目ID>/deploy_keys"

# 3. 本地再试一把强制 RSA：
ssh-keygen -t rsa -b 4096 -C "fallback"
ssh-add ~/.ssh/id_rsa
ssh -i ~/.ssh/id_rsa -T git@gitlab.gbox.one
