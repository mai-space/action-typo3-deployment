# ⚙ GitHub Action for TYPO3 Deployments

A GitHub Action to deploy your TYPO3 project via ssh and rsync to your server

![TYPO3](https://img.shields.io/static/v1?style=for-the-badge&message=V12&color=FF8700&logo=TYPO3&logoColor=white&label=TYPO3)
![GitHub Action](https://img.shields.io/badge/CI/CD-282a2e?style=for-the-badge&logo=githubactions&logoColor=367cfe&label=Github%20Action)

## ✨ FEATURES

- ✅ Deploy your TYPO3 Project via ssh and rsync
- ✅ Use a private key to authenticate
- ✅ Supports custom composer bin path
- ✅ Use a custom ssh port
- ✅ Use it context dependent
- ✅ Supports custom TYPO3 file storages
- ✅ Supports custom PHP versions
- ✅ Clean and readable structure on your server
- ✅ Updates TYPO3 assets, like database, languages and cache after each deployment

## 🔧 HOW TO USE

In this section you will find a quick guide on how to use this action.

### 🧪 CONFIGURATION

In your `.github/workflows` folder create a new file, e.g. `deploy.yml` and add the following content:

```yaml
  - name: Deployment
    uses: mai-space/action-typo3-deployment/@main
    with:
      sshPrivateKey: ${{ secrets.DEPLOY_PRIVATE_KEY }}
      remoteUsername: 'your-ssh-user'
      remoteHost: 'your.host.server'
      remotePath: '/path/to/your/typo3-root'
      baseUrl: 'https://www.your-url.dev'
      typo3Context: 'YOUR_CONTEXT/YOUR_HOSTER'
      additionalFileStorages: 'fileadmin,fileadmin2,...'
      sshPort: 22
      phpVersion: '8.2'
      composerBinPath: '/bin'
```

## 🧡 SPECIAL THANKS

This Action is inspired by the workflows of my colleagues at [IW Medien](https://www.iwmedien.de/).
Especially thank you, Sune Donath for your great work and support!
