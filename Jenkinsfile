/**
properties([
  parameters([
    string(defaultValue: '1.0', description: 'Current version number', name: 'VERSION'),
    text(defaultValue: '', description: 'A list of changes', name: 'CHANGES'),
    booleanParam(defaultValue: true, description: 'Whether to upload to Github for release or not', name: 'GITHUB_PRERELEASE'),
    booleanParam(defaultValue: false, description: 'If build should be marked as pre-release', name: 'GITHUB_PRERELEASE'),
    string(defaultValue: 'ayufan-pine64', description: 'GitHub username or organization', name: 'GITHUB_USER'),
    string(defaultValue: 'android-7.1', description: 'GitHub repository', name: 'GITHUB_REPO'),
    booleanParam(defaultValue: true, description: 'Select if you want to build desktop version.', name: 'BUILD_DESKTOP'),
    booleanParam(defaultValue: true, description: 'Select if you want to build TV version.', name: 'BUILD_TV'),
  ])
])
*/

node('docker && android-build') {
  timestamps {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
      stage "Environment"
      dir('build-environment') {
        checkout scm
      }
      def environment = docker.build('build-environment-rock64:android-7.1', 'build-environment')

      environment.inside {
        stage 'Sources'
        sh '''#!/bin/bash

        set -xe

        export HOME=$WORKSPACE
        export USER=jenkins

        repo init -u https://android.googlesource.com/platform/manifest -b android-7.1.2_r6 --depth=1
        rm -rf .repo/local_manifests
        git clone https://github.com/ayufan-rock64/android-manifests -b nougat-7.1 .repo/local_manifests

        repo sync -j 20 -c --force-sync
        '''

        withEnv([
          "VERSION=$VERSION",
          "CHANGES=$CHANGES",
          "GITHUB_USER=$GITHUB_USER",
          "GITHUB_REPO=$GITHUB_REPO"
        ]) {
          stage 'Test'
          sh '''#!/bin/bash
            # use -ve, otherwise we could leak GITHUB_TOKEN...
            set -ve
            shopt -s nullglob

            export HOME=$WORKSPACE
            export USER=jenkins

            if curl -s --fail "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/versions/$VERSION/CHANGES.md"; then
              echo "Version already exist."
              exit 1
            fi
          '''
        }

        withEnv([
          "VERSION=$VERSION",
          'USE_CCACHE=true',
          'CCACHE_DIR=/var/lib/ccache',
        ]) {
            stage 'Prepare'
            sh '''#!/bin/bash
              export CCACHE_DIR=$PWD/ccache
              prebuilts/misc/linux-x86/ccache/ccache -M 0 -F 0
              rm -rf rockdev/
              git -C kernel clean -fdx
              git -C u-boot clean -fdx
            '''
        }

        withEnv([
          "VERSION=$VERSION",
          'USE_CCACHE=true',
          'ANDROID_JACK_VM_ARGS=-Xmx6g -Dfile.encoding=UTF-8 -XX:+TieredCompilation',
          'ANDROID_NO_TEST_CHECK=true'
        ]) {
          stage 'Regular Rock64'
          if (params.BUILD_DESKTOP) {
            sh '''#!/bin/bash
              export CCACHE_DIR=$PWD/ccache
              export HOME=$WORKSPACE
              export USER=jenkins

              device/rockchip/common/build_base.sh \
                -a arm64 \
                -l rock64_regular-eng \
                -u rk3328_box_defconfig \
                -k rockchip_smp_nougat_defconfig \
                -d rk3328-rock64 \
                -j $(($(nproc)+1))
            '''
          } else {
            echo 'Desktop version disabled.'
          }

          stage 'TV Rock64'
          if (params.BUILD_TV) {
            sh '''#!/bin/bash
              export CCACHE_DIR=$PWD/ccache
              export HOME=$WORKSPACE
              export USER=jenkins

              device/rockchip/common/build_base.sh \
                -a arm64 \
                -l rock64_atv-userdebug \
                -u rk3328_box_defconfig \
                -k rockchip_smp_nougat_defconfig \
                -d rk3328-rock64 \
                -j $(($(nproc)+1))
            '''
          } else {
            echo 'TV version disabled.'
          }

          stage 'TV Rockbox'
          if (params.BUILD_TV) {
            sh '''#!/bin/bash
              export CCACHE_DIR=$PWD/ccache
              export HOME=$WORKSPACE
              export USER=jenkins

              device/rockchip/common/build_base.sh \
                -a arm64 \
                -l rockbox_atv-userdebug \
                -u rk3328_box_defconfig \
                -k rockchip_smp_nougat_defconfig \
                -d rk3328-rockbox \
                -j $(($(nproc)+1))
            '''
          } else {
            echo 'TV version disabled.'
          }

          stage 'Package'
          sh '''#!/bin/bash
            export HOME=$WORKSPACE
            export USER=jenkins

            set -xe

            cd rockdev/

            for variant in Image-*; do
              name="${JOB_NAME}-${variant/Image-/}-v${VERSION}-r${BUILD_NUMBER}"
              mv "$variant" "$name"

              mkdir -p "${name}-update"
              mv "${name}/update.img" "${name}-update/"
              cp "../vendor/ayufan/rockchip/idbloader.img" "${name}/"
              zip -r "${name}.zip" "$name/" &
              zip -r "${name}-update.zip" "${name}-update/" &
              ../vendor/ayufan/rockchip/rkimage "$name/" "$name-raw.img" &
            done

            wait
          '''
        }

        if (params.GITHUB_UPLOAD) {
          withEnv([
            "VERSION=$VERSION",
            "CHANGES=$CHANGES",
            "PRERELEASE=$GITHUB_PRERELEASE",
            "GITHUB_USER=$GITHUB_USER",
            "GITHUB_REPO=$GITHUB_REPO"
          ]) {
            stage 'Freeze'
            sh '''#!/bin/bash
              # use -ve, otherwise we could leak GITHUB_TOKEN...
              set -ve
              shopt -s nullglob

              export HOME=$WORKSPACE
              export USER=jenkins

              repo manifest -r -o manifest.xml

              echo "{\\"message\\":\\"Add $VERSION changes\\", \\"committer\\":{\\"name\\":\\"Jenkins\\",\\"email\\":\\"jenkins@ayufan.eu\\"},\\"content\\":\\"$(echo "$CHANGES" | base64 -w 0)\\"}" | \
                curl --fail -X PUT -H "Authorization: token $GITHUB_TOKEN" -d @- \
                "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/versions/$VERSION/CHANGES.md"

              echo "{\\"message\\":\\"Add $VERSION manifest\\", \\"committer\\":{\\"name\\":\\"Jenkins\\",\\"email\\":\\"jenkins@ayufan.eu\\"},\\"content\\":\\"$(base64 -w 0 manifest.xml)\\"}" | \
                curl --fail -X PUT -H "Authorization: token $GITHUB_TOKEN" -d @- \
                "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/versions/$VERSION/manifest.xml"
            '''

            stage 'Release'
            sh '''#!/bin/bash
              set -xe
              shopt -s nullglob

              github-release release \
                  --tag "${VERSION}" \
                  --name "$VERSION: $BUILD_TAG" \
                  --description "${CHANGES}\n\n${BUILD_URL}" \
                  --draft

              github-release upload \
                  --tag "${VERSION}" \
                  --name "manifest.xml" \
                  --file "manifest.xml"

              for file in rockdev/*.zip rockdev/*.gz; do
                github-release upload \
                    --tag "${VERSION}" \
                    --name "$(basename "$file")" \
                    --file "$file" &
              done

              wait

              if [[ "$PRERELEASE" == "true" ]]; then
                github-release edit \
                  --tag "${VERSION}" \
                  --name "$VERSION: $BUILD_TAG" \
                  --description "${CHANGES}\n\n${BUILD_URL}" \
                  --pre-release
              else
                github-release edit \
                  --tag "${VERSION}" \
                  --name "$VERSION: $BUILD_TAG" \
                  --description "${CHANGES}\n\n${BUILD_URL}"
              fi
            '''
          }
        } else {
          stage 'Freeze'
          echo 'Upload disabled'

          stage 'Release'
          echo 'Upload disabled'
        }
      }
    }
  }
}
