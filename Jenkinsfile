
properties([
  parameters([
    string(defaultValue: '0.3.14', description: 'Current version number', name: 'VERSION'),
    text(defaultValue: '', description: 'A list of changes', name: 'CHANGES'),
    booleanParam(defaultValue: false, description: 'Whether to upload to Github for release or not', name: 'GITHUB_UPLOAD'),
    booleanParam(defaultValue: true, description: 'If build should be marked as pre-release', name: 'GITHUB_PRERELEASE'),
    string(defaultValue: 'chinper', description: 'GitHub username or organization', name: 'GITHUB_USER'),
    string(defaultValue: 'android-7.1', description: 'GitHub repository', name: 'GITHUB_REPO'),
    booleanParam(defaultValue: false, description: 'full repo', name: 'FULL_REPO'),
    booleanParam(defaultValue: false, description: 'Select if you want to build desktop version.', name: 'BUILD_DESKTOP'),
    booleanParam(defaultValue: true, description: 'Select if you want to build TV rock64 version.', name: 'BUILD_TV'),
    booleanParam(defaultValue: false, description: 'Select if you want to build TV rockbox version.', name: 'BUILD_TV2'),
    booleanParam(defaultValue: false, description: 'If build should be REDOWNLOAD', name: 'GITHUB_REDOWNLOAD'),
  ])
])


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
        
        # git config --global http.postBuffer 1048576000
        export HOME=$WORKSPACE
        export USER=jenkins
        
        # [ -d ~/.repo ] && rm -Rf ~/.repo
        # [ -d ~/.repoconfig ] && rm -Rf ~/.repoconfig
        [ -d ~/bin ] || mkdir ~/bin
        curl https://storage.googleapis.com/git-repo-downloads/repo-1 > ~/bin/repo
        chmod a+x ~/bin/repo

        [ -d ~/.repo ] || python ~/bin/repo init -u https://android.googlesource.com/platform/manifest -b android-7.1.2_r6 --depth=1

        '''
        
        if (params.FULL_REPO) {
          sh '''#!/bin/bash
          set -xe
          export HOME=$WORKSPACE
          export USER=jenkins
          
          rm -rf .repo/local_manifests
          git clone https://github.com/chinper/android-manifests.git -b nougat-7.1 .repo/local_manifests
          python ~/bin/repo sync -j 20 -c --force-sync

          '''
        }

        sh '''#!/bin/bash
        set -xe
        export HOME=$WORKSPACE
        export USER=jenkins

        # below get 
        # python3 --version
        gradle wrapper --gradle-version 2.1
        ./gradlew
        # if (params.GITHUB_REDOWNLOAD) {
        #   repo sync -j 20 -c --force-sync
        # }
        # [ ! -e vendor/opengapps/sources ] && mkdir vendor/opengapps/sources
        # [ ! -e vendor/opengapps/sources/all ] && \
        #   git clone https://gitlab.opengapps.org/opengapps/all.git vendor/opengapps/sources/all
        # [ ! -e vendor/opengapps/sources/arm ] && \
        #   git clone https://gitlab.opengapps.org/opengapps/arm.git vendor/opengapps/sources/arm
        # [ ! -e vendor/opengapps/sources/arm64 ] && \
        #   git clone https://gitlab.opengapps.org/opengapps/arm64.git vendor/opengapps/sources/arm64
        # [ -e vendor/opengapps/sources/opengapps ] && \
        # cd vendor/opengapps/sources/opengapps/ && \
        # ./download_sources.sh --shallow arm64

        cd ~/vendor/opengapps/sources
        for d in ./*/ ; do (cd "$d" && git lfs pull); done      
        
        
        # cd ~/vendor/opengapps/build
        # git lfs install
        # ~/.repo/repo/repo forall -c git lfs pull
        
        
        echo "remove some duplicated folder..."
        cd ~/vendor/opengapps/atv-build/modules
        for d in *; do 
            if [ -d "$d" ]; then
                # ls -d ../../build/modules/*
                [ -d ../../build/modules/$d ] &&  echo "$d" && rm -Rfv ../../build/modules/$d
            fi
        done
        cd ~/        

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

            #if curl -s --fail "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/versions/$VERSION/CHANGES.md"; then
            #  echo "Version already exist."
            #  exit 1
            #fi
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
              # ./gradlew clean build
            '''
        }

        withEnv([
          "VERSION=$VERSION",
          'USE_CCACHE=true',
          'USE_NINJA=false',
          'ANDROID_JACK_VM_ARGS=-Xmx8192m -Dfile.encoding=UTF-8 -XX:+TieredCompilation -XX:MaxJavaStackTraceDepth=-1 -Djava.io.tmpdir=/tmp',
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
          if (params.BUILD_TV2) {
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
