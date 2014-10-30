module.exports = function(grunt) {

  // project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      options: {
        globals: {
          jQuery: true,
          console: true,
          module: true,
          document: true
        }
      },
      build: ['gruntfile.js', 'src/**/*.js']
    },
    concat: {
      options: {
        separator: ';'
      },
      build: {
        src: ['src/**/*.js'],
        dest: 'tmp/js/<%= pkg.name %>.js'
      }
    },
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
      },
      build: {
        files: {
          'tmp/js/<%= pkg.name %>.min.js': ['<%= concat.build.dest %>']
        }
      }
    },
    zip: {
      // example build target for static resources
      build: {
        options: {
          base: 'tmp/'
        },
        src: ['tmp'],
        dest: 'build/staticresources/<%= pkg.name %>.resource'
      }
    },
    copy: {
      main: {
        files: [
          { expand: true, cwd: 'src/', src: ['img/*'], dest: 'tmp/' }
        ]
      }
    },
    /* grunt-ant-sfde retrieve */
    antretrieve: {
      options: {
        user: 'anders.nehlin@47demo.com',
        pass: '!QAZxsw2',
        token: 'pgfIhviWxV7NTpwRjm13b4IM'
      },
      // specify one retrieve target
      src: {
        serverurl:  'https://login.salesforce.com', // default => https://login.salesforce.com
        pkg: {
          staticresource: ['*'],
          apexclass:      ['*'],
          apextrigger:    ['*'],
          apexpage:       ['*']
        }
      }

    },

    antdeploy: {
      // define global options for all deploys
      options: {
        root: 'build/',
        version: '29.0',
        runAllTests: true,
        rollbackOnError: true
      },
      // create individual deploy targets. these can be
      // individual orgs or even the same org with different packages
      dev1:  {
        options: {
          user: 'anders.nehlin@47demo.com',
          pass: '!QAZxsw2',
          token: 'pgfIhviWxV7NTpwRjm13b4IM',
          serverurl: 'https://login.salesforce.com' // default => https://login.salesforce.com
        },
        pkg: {
          staticresource: ['*'],
          apexclass:      ['*'],
          apextrigger:    ['*'],
          apexpage:       ['*']
        },
        // tests: ['Test_CaseNewExtension', 'Test_CaseProductController', 'Test_CaseProductTriggers']
      },
    },

    clean: {
      build: ['tmp', 'build/package.xml']
    },

    // Deploy to git repository
    'gh-pages': {
      options: {
        components: '**',
        branch: 'master',
        repo: 'https://github.com/anehlin/softholm-grunt-git'
      },
      src: ['**']
    }

  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-zipstream');
  grunt.loadNpmTasks('grunt-ant-sfdc');
  grunt.loadNpmTasks('grunt-gh-pages');

  grunt.registerTask('run_scheduled_job', 'Scheduling job for deploy', function(endDate) {

    var done = this.async();
    var moment = require('moment');

    var cronJob = require('cron').CronJob
      , exec = require('child_process').exec
      , path = require('path')
      , running = false
      ;

    var run = function(what) {
      if (running === true) {
        return;
      }
      running = true;

      // by default, just run grunt
      what = what || 'grunt';

      exec(what, function(err, stdout, stderr) {
        if (err || stderr) {
          console.log(err);
        }
        /* log the stdout if needed*/
        console.log(stdout);
        console.log('Completed deploy ' + moment().format('YYYY-MM-DD HH:mm'));
        running = false;
        done(true);
      });
    };

    new cronJob('00 10 16 * * *', function(){
        console.log('Starting deploy ' + new Date());
        var what = 'grunt antdeploy';
        run(what);
    }, null, true);

    // var done = this.async();

    // if (arguments.length === 0) {
    //   grunt.log.writeln("Please, add the endDate argument");
    //   done(true);
    // }
    // else {
    //   console.log("The scheduled job will be executed every day until " + endDate);
    // }

    // var moment = require('moment');
    // var exec = require('child_process').exec;
    // var running = false;

    // var run = function(what) {
    //   if (running === true) return;
    //   var now = moment().format('YYYY-MM-DD');
    //   running = true;
    //   console.log('Running deploy at ' + moment().format('YYYY-MM-DD HH:mm'));
    //   // by default, just run grunt
    //   what = what || 'grunt';
    //   exec(what, function(err, stdout, stderr) {
    //     if (err || stderr) {
    //       console.log(err);
    //       console.log(stderr);
    //     }
    //     console.log(stdout);
    //     running = false;
    //     if(now == endDate) {
    //       console.log('Deploy completed.');
    //       done(true);
    //     }
    //   })
    // }

    // setInterval(function() {
    //   run('grunt antdeploy')
    // }, 1 * 60 * 60 * 1000); // once a day

  });


  // custom task to write the -meta.xml file for the metadata deployment
  grunt.registerTask('write-meta', 'Write the required salesforce metadata', function() {
    grunt.log.writeln('Writing metadata...');
    var sr = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">',
      '  <cacheControl>Public</cacheControl>',
      '  <contentType>application/zip</contentType>',
      '  <description>MyTest Description</description>',
      '</StaticResource>'
    ];
    var dest = grunt.template.process('<%= zip.build.dest %>') + '-meta.xml';
    grunt.file.write(dest, sr.join('\n'));
  });

  // default task (no deploy)
  grunt.registerTask('default', ['clean', 'jshint', 'concat', 'uglify', 'copy', 'zip', 'write-meta' ]);

  // deploy
  grunt.registerTask('deploy', ['gh-pages' , 'antdeploy']);


};